#!/usr/bin/env bash
# 06.3 run --all check. Re-runnable. The cache is removed first.
# Run this from start/ or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache database/.terragrunt-cache service/.terragrunt-cache

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

forbid() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if code_grep "$file" "$pattern"; then
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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. The chain is network, then database, then service."
need database/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'database should depend on ../network'
need database/terragrunt.hcl 'name[[:space:]]*=[[:space:]]*"mock-network-name"' \
  'database should mock the network name'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./database"' \
  'service should depend on ../database'
need service/terragrunt.hcl 'name[[:space:]]*=[[:space:]]*"mock-db-name"' \
  'service should mock the database name'
need service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.database\.outputs\.name' \
  'service note should be the database name output'
need database/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
  'database note should be the network name output'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid network/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
pass "chain"

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

echo "== 4. run --all plan"
all_plan="$(mktemp)"
terragrunt --no-color --non-interactive run --all -- plan -input=false -no-color >"$all_plan" 2>&1
assert_units "$all_plan" $'database\nnetwork\nservice' "run --all plan units"
if ! grep -Fq 'STDOUT [database]' "$all_plan" || ! grep -F 'STDOUT [database]' "$all_plan" | grep -Fq '"mock-network-name"'; then
  echo "FAIL  database plan did not use mock-network-name"
  rm -f "$all_plan"
  exit 1
fi
if ! grep -F 'STDOUT [service]' "$all_plan" | grep -Fq '"mock-db-name"'; then
  echo "FAIL  service plan did not use mock-db-name"
  rm -f "$all_plan"
  exit 1
fi
if ! grep -F 'STDOUT [network]' "$all_plan" | grep -Fq '"network unit"'; then
  echo "FAIL  network plan did not show note network unit"
  rm -f "$all_plan"
  exit 1
fi
plan_count="$(grep -c "Plan: 3 to add, 0 to change, 0 to destroy." "$all_plan")"
if [[ "$plan_count" -ne 3 ]]; then
  echo "FAIL  expected 3 plans that add 3 resources, saw ${plan_count}"
  rm -f "$all_plan"
  exit 1
fi
pass "run --all plan"
rm -f "$all_plan"

echo "== 5. run --graph, in a copy whose git root is this lecture."
# --graph searches for dependents up to the git root. Other lectures in this
# repository do not all parse, so the search runs in a temporary copy.
graph_root="$(mktemp -d)"
python3 - "${graph_root}/lab" <<'PY'
import shutil
import sys
from pathlib import Path

dest = Path(sys.argv[1])

def skip_cache(directory, names):
    return [name for name in names if name == ".terragrunt-cache"]

shutil.copytree(Path("."), dest, ignore=skip_cache)
PY
git -C "${graph_root}/lab" init -q

run_graph() {
  local unit="$1"
  local log="$2"
  set +e
  (
    cd "${graph_root}/lab/${unit}"
    terragrunt --no-color --non-interactive run --graph -- plan -input=false -no-color
  ) >"$log" 2>&1
  local status=$?
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "FAIL  run --graph in ${unit} exited ${status}"
    cat "$log"
    exit 1
  fi
}

graph_network="$(mktemp)"
graph_database="$(mktemp)"
graph_service="$(mktemp)"
run_graph network "$graph_network"
run_graph database "$graph_database"
run_graph service "$graph_service"
assert_units "$graph_network" $'database\nnetwork\nservice' "--graph from network"
assert_units "$graph_database" $'database\nservice' "--graph from database"
assert_units "$graph_service" "service" "--graph from service"
pass "run --graph"
rm -rf "$graph_root" "$graph_network" "$graph_database" "$graph_service"

echo "== 6. run --all apply passes each name output to the next unit."
terragrunt --no-color --non-interactive run --all -- apply -input=false -no-color
net_name="$(cd network && terragrunt --no-color output -raw name)"
db_note="$(cd database && terragrunt --no-color output -raw note)"
db_name="$(cd database && terragrunt --no-color output -raw name)"
svc_note="$(cd service && terragrunt --no-color output -raw note)"
if [[ "$db_note" != "$net_name" ]]; then
  echo "FAIL  database note '${db_note}' is not network name '${net_name}'"
  exit 1
fi
if [[ "$svc_note" != "$db_name" ]]; then
  echo "FAIL  service note '${svc_note}' is not database name '${db_name}'"
  exit 1
fi
if [[ "$db_note" == "mock-network-name" || "$svc_note" == "mock-db-name" ]]; then
  echo "FAIL  apply kept a mock output"
  exit 1
fi
if [[ ! "$net_name" =~ ^net- || ! "$db_name" =~ ^db- || ! "$svc_note" =~ ^db- ]]; then
  echo "FAIL  unexpected names net=${net_name} db=${db_name} svc_note=${svc_note}"
  exit 1
fi
pass "apply chain (${net_name} -> ${db_name} -> service)"

echo "== 7. run --all destroy runs dependents first."
destroy_log="$(mktemp)"
terragrunt --no-color --non-interactive run --all -- destroy -input=false -no-color >"$destroy_log" 2>&1
python3 - "$destroy_log" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
order = []
for line in lines:
    for unit in ("service", "database", "network"):
        if f"STDOUT [{unit}]" in line and "Destroy complete" in line:
            order.append(unit)
if order != ["service", "database", "network"]:
    print("FAIL  destroy order was", order)
    sys.exit(1)
PY
pass "destroy order"
rm -f "$destroy_log"

rm -rf network/.terragrunt-cache database/.terragrunt-cache service/.terragrunt-cache
echo "PASS  06.3 run all"
