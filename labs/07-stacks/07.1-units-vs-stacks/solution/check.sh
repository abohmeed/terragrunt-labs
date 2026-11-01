#!/usr/bin/env bash
# 07.1 units vs stacks check. Re-runnable. Generated stacks and caches are removed first.
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

echo "== 2. A unit is terragrunt.hcl. A stack is terragrunt.stack.hcl. _envcommon is neither."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid units/record/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid units/record/terragrunt.hcl '_envcommon' \
  'the record unit replaces _envcommon. Do not include it.'
[[ -f units/record/terragrunt.hcl ]]
[[ ! -f units/record/terragrunt.stack.hcl ]]
[[ -f _envcommon/record.hcl ]]
[[ ! -f _envcommon/terragrunt.hcl ]]
[[ ! -f stack/terragrunt.hcl ]]
[[ -f stack/terragrunt.stack.hcl ]]
need _envcommon/record.hcl 'source[[:space:]]*=' \
  '_envcommon/record.hcl should still hold the old terraform source'
need legacy/dev/terragrunt.hcl '_envcommon/record\.hcl' \
  'leave the legacy dev include of _envcommon in place'
need legacy/prod/terragrunt.hcl '_envcommon/record\.hcl' \
  'leave the legacy prod include of _envcommon in place'
need stack/terragrunt.stack.hcl 'unit[[:space:]]+"record"' \
  'add a unit "record" block in stack/terragrunt.stack.hcl'
need stack/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./units/record"' \
  'set source = "../units/record" on the stack unit'
need stack/terragrunt.stack.hcl 'path[[:space:]]*=[[:space:]]*"record"' \
  'set path = "record" on the stack unit'
forbid stack/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO source'
forbid stack/terragrunt.stack.hcl '_envcommon' \
  'the stack does not include _envcommon'
pass "unit, stack, and envcommon"

echo "== 3. The legacy include still plans. The direct unit is one Terraform run."
assert_engine units/record
legacy_log="$(mktemp)"
(
  cd legacy/dev
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$legacy_log" 2>&1
if [[ "$(plan_count "$legacy_log")" -lt 1 ]]; then
  echo "FAIL  legacy/dev plan was not 3 to add"
  cat "$legacy_log"
  rm -f "$legacy_log"
  exit 1
fi
if ! grep -q 'legacy include' "$legacy_log"; then
  echo "FAIL  legacy/dev plan did not keep the legacy note"
  cat "$legacy_log"
  rm -f "$legacy_log"
  exit 1
fi
pass "legacy dev plan"
rm -f "$legacy_log"

unit_log="$(mktemp)"
(
  cd units/record
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$unit_log" 2>&1
if [[ "$(plan_count "$unit_log")" -lt 1 ]]; then
  echo "FAIL  units/record plan was not 3 to add"
  cat "$unit_log"
  rm -f "$unit_log"
  exit 1
fi
if ! grep -q 'one unit' "$unit_log"; then
  echo "FAIL  units/record plan did not use note \"one unit\""
  cat "$unit_log"
  rm -f "$unit_log"
  exit 1
fi
pass "record unit plan"
rm -f "$unit_log"

echo "== 4. The stack directory is not a unit. Generate the unit, then plan it."
stack_run="$(mktemp)"
set +e
(
  cd stack
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$stack_run" 2>&1
stack_status=$?
set -e
if [[ "$stack_status" -eq 0 ]]; then
  echo "FAIL  terragrunt run plan succeeded in stack/. That directory is not a unit."
  rm -f "$stack_run"
  exit 1
fi
if ! grep -q "does not contain a terragrunt.hcl file" "$stack_run"; then
  echo "FAIL  stack/ run plan failed for a reason other than the missing terragrunt.hcl"
  cat "$stack_run"
  rm -f "$stack_run"
  exit 1
fi
pass "stack directory is not a unit"
rm -f "$stack_run"

(
  cd stack
  terragrunt --no-color stack generate
)
[[ -f stack/.terragrunt-stack/record/terragrunt.hcl ]]
[[ ! -f stack/.terragrunt-stack/record/terragrunt.stack.hcl ]]
if grep -E '_envcommon' stack/.terragrunt-stack/record/terragrunt.hcl | grep -Eqv '^[[:space:]]*#'; then
  echo "FAIL  the generated unit includes _envcommon"
  exit 1
fi
pass "stack generate"

find_log="$(mktemp)"
terragrunt --no-color find >"$find_log" 2>&1
if grep -q '_envcommon' "$find_log"; then
  echo "FAIL  terragrunt find listed _envcommon. That directory is not a unit or a stack."
  cat "$find_log"
  rm -f "$find_log"
  exit 1
fi
if ! grep -qx 'units/record' "$find_log"; then
  echo "FAIL  terragrunt find did not list units/record"
  cat "$find_log"
  rm -f "$find_log"
  exit 1
fi
if ! grep -qx 'stack' "$find_log"; then
  echo "FAIL  terragrunt find did not list the stack directory"
  cat "$find_log"
  rm -f "$find_log"
  exit 1
fi
pass "find skips _envcommon"
rm -f "$find_log"

gen_log="$(mktemp)"
(
  cd stack/.terragrunt-stack/record
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$gen_log" 2>&1
if [[ "$(plan_count "$gen_log")" -lt 1 ]]; then
  echo "FAIL  generated record plan was not 3 to add"
  cat "$gen_log"
  rm -f "$gen_log"
  exit 1
fi
pass "generated unit plan"
rm -f "$gen_log"
assert_engine stack/.terragrunt-stack/record

clean_runtime
echo "PASS  07.1 units vs stacks"
