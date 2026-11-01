#!/usr/bin/env bash
# 06.5 scoping check. Re-runnable. The cache is removed first.
# Run this from start/ or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache apps/api/.terragrunt-cache apps/worker/.terragrunt-cache apps/legacy/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

code_grep() {
  local file="$1"
  local pattern="$2"
  grep -E "$pattern" "$file" | grep -Eqv '^[[:space:]]*#'
}

need() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! code_grep "$file" "$pattern"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

units_of() {
  local log="$1"
  { grep -oE 'STDOUT \[[^]]+\]' "$log" || true; } | sed -E 's/^STDOUT \[//; s/\]$//' | LC_ALL=C sort -u
}

assert_units() {
  local log="$1"
  local expected="$2"
  local message="$3"
  local got
  got="$(units_of "$log")"
  if [[ "$got" != "$expected" ]]; then
    echo "FAIL  ${message}"
    echo "got:"
    printf '%s\n' "$got"
    echo "expected:"
    printf '%s\n' "$expected"
    exit 1
  fi
}

run_in() {
  local dir="$1"
  local log="$2"
  shift 2
  (
    cd "$dir"
    terragrunt --no-color --non-interactive "$@"
  ) >"$log" 2>&1
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Each app depends on the shared network and can plan from a mock."
for app in api worker legacy; do
  need "apps/${app}/terragrunt.hcl" 'config_path[[:space:]]*=[[:space:]]*"\.\./\.\./network"' \
    "${app} should depend on ../../network"
  need "apps/${app}/terragrunt.hcl" 'name[[:space:]]*=[[:space:]]*"mock-network-name"' \
    "${app} should mock the network name"
  need "apps/${app}/terragrunt.hcl" 'mock_outputs_allowed_terraform_commands[[:space:]]*=[[:space:]]*\[[^]]*plan[^]]*destroy' \
    "${app} should allow mocks for plan and destroy"
done
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
pass "units"

echo "== 3. Engine."
version_log="$(mktemp)"
(
  cd network
  terragrunt --no-color run -- version
) >"$version_log" 2>&1
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
  cat "$version_log"
  rm -f "$version_log"
  exit 1
fi
if grep -q "OpenTofu" "$version_log"; then
  echo "FAIL  OpenTofu ran. terraform_binary should select Terraform."
  rm -f "$version_log"
  exit 1
fi
pass "engine"
rm -f "$version_log"

echo "== 4. From apps/, external network stays out of the queue."
apps_plan="$(mktemp)"
run_in apps "$apps_plan" run --all -- plan -input=false -no-color
assert_units "$apps_plan" $'api\nlegacy\nworker' "default apps plan"
pass "external network excluded by default"
rm -f "$apps_plan"

echo "== 5. --queue-exclude-external is the old name for that default."
qee="$(mktemp)"
set +e
run_in apps "$qee" run --all --queue-exclude-external -- plan -input=false -no-color
qee_status=$?
set -e
if [[ "$qee_status" -ne 0 ]]; then
  if grep -q "no longer supported" "$qee"; then
    pass "queue-exclude-external retired; the default already excludes external units"
  else
    echo "FAIL  --queue-exclude-external failed"
    cat "$qee"
    rm -f "$qee"
    exit 1
  fi
else
  if ! grep -Fq "External dependencies are now excluded by default" "$qee"; then
    echo "FAIL  --queue-exclude-external did not warn that it is now the default"
    cat "$qee"
    rm -f "$qee"
    exit 1
  fi
  assert_units "$qee" $'api\nlegacy\nworker' "--queue-exclude-external units"
  pass "queue-exclude-external"
fi
rm -f "$qee"

echo "== 6. run rejects --exclude-dir. --queue-exclude-dir and --filter drop legacy."
bad="$(mktemp)"
set +e
run_in apps "$bad" run --all --exclude-dir ./legacy -- plan -input=false -no-color
bad_status=$?
set -e
if [[ "$bad_status" -eq 0 ]]; then
  echo "FAIL  run accepted --exclude-dir"
  rm -f "$bad"
  exit 1
fi
if ! grep -Fq "not a valid flag" "$bad"; then
  echo "FAIL  --exclude-dir was rejected for an unexpected reason"
  cat "$bad"
  rm -f "$bad"
  exit 1
fi
pass "run rejects --exclude-dir"
rm -f "$bad"

excluded="$(mktemp)"
run_in apps "$excluded" run --all --queue-exclude-dir ./legacy -- plan -input=false -no-color
assert_units "$excluded" $'api\nworker' "--queue-exclude-dir ./legacy"
pass "queue-exclude-dir"
rm -f "$excluded"

filtered="$(mktemp)"
run_in apps "$filtered" run --all --filter='!./legacy' -- plan -input=false -no-color
assert_units "$filtered" $'api\nworker' "--filter !./legacy"
pass "filter"
rm -f "$filtered"

echo "== 7. From this directory, run --all includes network and the three apps."
root_plan="$(mktemp)"
terragrunt --no-color --non-interactive run --all -- plan -input=false -no-color >"$root_plan" 2>&1
assert_units "$root_plan" $'apps/api\napps/legacy\napps/worker\nnetwork' "lecture-root plan"
pass "lecture root queue"
rm -f "$root_plan"

echo "== 8. Apply, then prove a destroy from apps/ leaves network in place."
terragrunt --no-color --non-interactive run --all -- apply -input=false -no-color
net_name="$(cd network && terragrunt --no-color output -raw name)"
if [[ ! "$net_name" =~ ^net-[a-z]+-[a-z]+$ ]]; then
  echo "FAIL  network name was '${net_name}'"
  exit 1
fi
for app in api worker legacy; do
  note="$(cd "apps/${app}" && terragrunt --no-color output -raw note)"
  if [[ "$note" != "$net_name" ]]; then
    echo "FAIL  ${app} note '${note}' is not network name '${net_name}'"
    exit 1
  fi
done
pass "apply linked the apps to ${net_name}"

safe="$(mktemp)"
run_in apps "$safe" run --all -- destroy -input=false -no-color
assert_units "$safe" $'api\nlegacy\nworker' "safe destroy units"
if grep -F "STDOUT [../network]" "$safe" | grep -q "Destroy complete"; then
  echo "FAIL  destroy from apps/ also destroyed network"
  rm -f "$safe"
  exit 1
fi
rm -f "$safe"
net_after="$(cd network && terragrunt --no-color output -raw name)"
if [[ "$net_after" != "$net_name" ]]; then
  echo "FAIL  network name changed from '${net_name}' to '${net_after}'"
  exit 1
fi
pass "destroy from apps/ left network"

echo "== 9. --queue-include-external is the destroy trap."
terragrunt --no-color --non-interactive --working-dir apps run --all -- apply -input=false -no-color
trap_log="$(mktemp)"
run_in apps "$trap_log" run --all --queue-include-external -- destroy -input=false -no-color
assert_units "$trap_log" $'../network\napi\nlegacy\nworker' "destroy trap units"
if ! grep -F "STDOUT [../network]" "$trap_log" | grep -q "Destroy complete"; then
  echo "FAIL  include-external destroy did not destroy network"
  cat "$trap_log"
  rm -f "$trap_log"
  exit 1
fi
pass "include-external destroy removed network"
rm -f "$trap_log"
state_list="$(cd network && terragrunt --no-color run -- state list || true)"
if [[ -n "${state_list}" ]]; then
  echo "FAIL  network state still lists resources:"
  printf '%s\n' "$state_list"
  exit 1
fi
pass "network state is empty"

echo "== 10. --destroy-dependencies-check warns, then still destroys."
# The check looks for dependents up to the git root. Unfinished lectures in this
# repository do not parse, so run it in a copy whose git root is this lecture.
# The copy keeps .terragrunt-cache so the applied network state is still there.
terragrunt --no-color --non-interactive run --all -- apply -input=false -no-color
check_root="$(mktemp -d)"
python3 - "${check_root}/lab" <<'PY'
import shutil
import sys
from pathlib import Path

shutil.copytree(Path("."), Path(sys.argv[1]))
PY
git -C "${check_root}/lab" init -q
check_log="$(mktemp)"
(
  cd "${check_root}/lab/network"
  terragrunt --no-color --non-interactive run --destroy-dependencies-check -- destroy -auto-approve -input=false -no-color
) >"$check_log" 2>&1
if ! grep -Fq "Detected dependent units:" "$check_log"; then
  echo "FAIL  destroy did not report dependent units"
  cat "$check_log"
  rm -rf "$check_root"
  rm -f "$check_log"
  exit 1
fi
for app in apps/api apps/worker apps/legacy; do
  if ! grep -Fq "$app" "$check_log"; then
    echo "FAIL  dependent list missing ${app}"
    cat "$check_log"
    rm -rf "$check_root"
    rm -f "$check_log"
    exit 1
  fi
done
if ! grep -q "Destroy complete" "$check_log"; then
  echo "FAIL  the dependency check blocked the destroy"
  cat "$check_log"
  rm -rf "$check_root"
  rm -f "$check_log"
  exit 1
fi
pass "destroy-dependencies-check"
rm -rf "$check_root"
rm -f "$check_log"

rm -rf network/.terragrunt-cache apps/api/.terragrunt-cache apps/worker/.terragrunt-cache apps/legacy/.terragrunt-cache
echo "PASS  06.5 scoping"
