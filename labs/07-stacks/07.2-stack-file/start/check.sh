#!/usr/bin/env bash
# 07.2 stack file check. Re-runnable. Generated stacks and caches are removed first.
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

echo "== 2. The live stack names a unit and a nested stack."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need live/terragrunt.stack.hcl 'unit[[:space:]]+"edge"' \
  'add a unit "edge" block'
need live/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./units/record"' \
  'set the edge source to "../units/record"'
need live/terragrunt.stack.hcl 'path[[:space:]]*=[[:space:]]*"edge"' \
  'set the edge path to "edge"'
need live/terragrunt.stack.hcl 'stack[[:space:]]+"platform"' \
  'add a stack "platform" block'
need live/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./blueprints/platform"' \
  'set the platform source to "../blueprints/platform"'
need live/terragrunt.stack.hcl 'path[[:space:]]*=[[:space:]]*"platform"' \
  'set the platform path to "platform"'
forbid live/terragrunt.stack.hcl '"TODO"' \
  'replace the TODO sources and paths'
need blueprints/platform/terragrunt.stack.hcl 'find_in_parent_folders\("root.hcl"\)' \
  'leave the nested unit source anchored on root.hcl'
[[ ! -f live/terragrunt.hcl ]]
pass "stack file"

echo "== 3. Generate. The nested stack is generated, then its unit."
(
  cd live
  terragrunt --no-color stack generate
)
[[ -f live/.terragrunt-stack/edge/terragrunt.hcl ]]
[[ -f live/.terragrunt-stack/platform/terragrunt.stack.hcl ]]
[[ -f live/.terragrunt-stack/platform/.terragrunt-stack/record/terragrunt.hcl ]]
[[ ! -f live/.terragrunt-stack/edge/terragrunt.stack.hcl ]]
pass "stack generate"

echo "== 4. stack run plan runs both units on Terraform 1.17."
plan_log="$(mktemp)"
(
  cd live
  terragrunt --no-color --non-interactive stack run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if [[ "$(plan_count "$plan_log")" -ne 2 ]]; then
  echo "FAIL  expected two plans of 3 adds, got $(plan_count "$plan_log")"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'record unit' "$plan_log"; then
  echo "FAIL  stack plan did not use the record unit note"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "stack run plan"
rm -f "$plan_log"
assert_engine live/.terragrunt-stack/edge
assert_engine units/record

clean_runtime
echo "PASS  07.2 stack file"
