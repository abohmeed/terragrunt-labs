#!/usr/bin/env bash
# 07.4 stack generate check. Re-runnable. Generated stacks and caches are removed first.
# Run this from start/ after the TODO, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"

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

assert_tg() {
  local version_log
  version_log="$(mktemp)"
  terragrunt --version >"$version_log" 2>&1
  if ! grep -q "v1\.2\." "$version_log"; then
    echo "FAIL  terragrunt was not 1.2.x"
    cat "$version_log"
    rm -f "$version_log"
    exit 1
  fi
  pass "terragrunt 1.2.x"
  rm -f "$version_log"
}

assert_engine() {
  local dir="$1"
  local version_log
  version_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color run -- version
  ) >"$version_log" 2>&1
  if ! grep -q "Terraform v1\.17\." "$version_log"; then
    echo "FAIL  ${dir}: engine was not Terraform 1.17.x"
    cat "$version_log"
    rm -f "$version_log"
    exit 1
  fi
  if grep -q "OpenTofu" "$version_log"; then
    echo "FAIL  ${dir}: OpenTofu ran. terraform_binary should select Terraform."
    rm -f "$version_log"
    exit 1
  fi
  pass "${dir} engine"
  rm -f "$version_log"
}

clean_runtime() {
  find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
  find . \( -name '*.tfstate' -o -name '*.tfstate.*' \) -delete
}

plan_count() {
  local file="$1"
  grep -c "Plan: 3 to add, 0 to change, 0 to destroy." "$file" || true
}


clean_runtime

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. live/ is the stack. The source unit stays outside that directory."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
[[ -f live/terragrunt.stack.hcl ]]
[[ ! -f live/terragrunt.hcl ]]
[[ ! -f terragrunt.hcl ]]
need live/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./units/record"' \
  'unit sources should be ../units/record'
need live/terragrunt.stack.hcl 'unit[[:space:]]+"network"' \
  'keep the network unit'
need live/terragrunt.stack.hcl 'unit[[:space:]]+"service"' \
  'keep the service unit'
pass "stack file"

echo "== 3. stack generate writes .terragrunt-stack, and git ignores it."
(
  cd live
  terragrunt --no-color stack generate
)
[[ -f live/.terragrunt-stack/network/terragrunt.hcl ]]
[[ -f live/.terragrunt-stack/network/terragrunt.values.hcl ]]
[[ -f live/.terragrunt-stack/service/terragrunt.hcl ]]
[[ -f live/.terragrunt-stack/service/terragrunt.autoinclude.hcl ]]
if ! git check-ignore -q live/.terragrunt-stack; then
  echo "FAIL  .terragrunt-stack is not gitignored"
  git check-ignore -v live/.terragrunt-stack || true
  exit 1
fi
pass "generate and gitignore"

echo "== 4. stack run plan, then apply. stack output is not stack run output."
plan_log="$(mktemp)"
set +e
(
  cd live
  terragrunt --no-color --non-interactive stack run -- plan -input=false -no-color
) >"$plan_log" 2>&1
plan_status=$?
set -e
if [[ "$plan_status" -ne 0 || "$(plan_count "$plan_log")" -ne 2 ]]; then
  echo "FAIL  expected two plans of 3 adds, got $(plan_count "$plan_log") (exit ${plan_status})"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'mock-network-name' "$plan_log"; then
  echo "FAIL  cold service plan did not use the mock"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "stack run plan"
rm -f "$plan_log"

(
  cd live
  terragrunt --no-color --non-interactive stack run -- apply -input=false -no-color
)
out="$(mktemp)"
(
  cd live
  terragrunt --no-color stack output --format json
) >"$out"
python3 - "$out" << 'PY'
import json, sys
data = json.load(open(sys.argv[1]))
network, service = data["network"], data["service"]
if service["note"] != network["name"]:
    sys.exit(f"FAIL  service note {service['note']!r} is not network name {network['name']!r}")
if not str(network["name"]).startswith("net-"):
    sys.exit(f"FAIL  network name was {network['name']!r}")
if service["prefix"] != "svc" or network["prefix"] != "net":
    sys.exit(f"FAIL  prefixes were {network['prefix']!r} and {service['prefix']!r}")
print(f"PASS  stack output note is {network['name']}")
PY
rm -f "$out"
assert_engine live/.terragrunt-stack/network

echo "== 5. Destroy, then stack clean removes the generated directory."
(
  cd live
  terragrunt --no-color --non-interactive stack run -- destroy -input=false -no-color
  terragrunt --no-color stack clean
)
if [[ -d live/.terragrunt-stack ]]; then
  echo "FAIL  stack clean left .terragrunt-stack in place"
  exit 1
fi
pass "destroy and clean"

echo "== 6. Without a generated stack, stack run --no-stack-generate has no units."
empty_log="$(mktemp)"
(
  cd live
  terragrunt --no-color --non-interactive stack run --no-stack-generate -- plan -input=false -no-color
) >"$empty_log" 2>&1
if ! grep -q "No units discovered" "$empty_log"; then
  echo "FAIL  --no-stack-generate did not report that no units were discovered"
  cat "$empty_log"
  rm -f "$empty_log"
  exit 1
fi
pass "no-stack-generate"
rm -f "$empty_log"

clean_runtime
echo "PASS  07.4 stack generate"
