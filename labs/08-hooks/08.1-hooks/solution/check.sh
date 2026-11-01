#!/usr/bin/env bash
# 08.1 hooks check. Re-runnable. Caches are removed first.
# Run this from start/ after the TODOs, or from solution/.
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

echo "== 2. Hooks live on the unit. terraform_binary stays in root.hcl."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid unit/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need unit/terragrunt.hcl 'find_in_parent_folders\("root.hcl"\)' \
  'the unit should include root.hcl'
need unit/terragrunt.hcl 'before_hook[[:space:]]+"stamp_start"' \
  'add before_hook "stamp_start"'
need unit/terragrunt.hcl 'after_hook[[:space:]]+"stamp_done"' \
  'add after_hook "stamp_done"'
need unit/terragrunt.hcl 'error_hook[[:space:]]+"stamp_error"' \
  'add error_hook "stamp_error"'
need unit/terragrunt.hcl 'run_on_error[[:space:]]*=[[:space:]]*false' \
  'set run_on_error = false on the after hook'
need unit/terragrunt.hcl 'before hook: plan starts' \
  'the before hook should echo "before hook: plan starts"'
need unit/terragrunt.hcl 'after hook: plan finished' \
  'the after hook should echo "after hook: plan finished"'
need unit/terragrunt.hcl 'error hook: plan failed' \
  'the error hook should echo "error hook: plan failed"'
need unit/terragrunt.hcl 'deliberate plan failure' \
  'on_errors should match the deliberate plan failure'
need modules/record/variables.tf 'deliberate plan failure' \
  'the note validation should reject fail with "deliberate plan failure"'
pass "hook blocks"

echo "== 3. A successful plan runs the before hook and the after hook."
assert_engine unit
happy="$(mktemp)"
(
  cd unit
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$happy" 2>&1
if [[ "$(plan_count "$happy")" -lt 1 ]]; then
  echo "FAIL  plan was not 3 to add"
  cat "$happy"
  rm -f "$happy"
  exit 1
fi
if ! grep -q 'before hook: plan starts' "$happy"; then
  echo "FAIL  the before hook did not run"
  cat "$happy"
  rm -f "$happy"
  exit 1
fi
if ! grep -q 'after hook: plan finished' "$happy"; then
  echo "FAIL  the after hook did not run"
  cat "$happy"
  rm -f "$happy"
  exit 1
fi
if ! grep -q 'hooks lab' "$happy"; then
  echo "FAIL  plan did not keep note \"hooks lab\""
  cat "$happy"
  rm -f "$happy"
  exit 1
fi
if grep -q 'error hook: plan failed' "$happy"; then
  echo "FAIL  the error hook ran on a successful plan"
  rm -f "$happy"
  exit 1
fi
pass "successful plan"
rm -f "$happy"

echo "== 4. note=fail runs the error hook and skips the after hook."
fail="$(mktemp)"
set +e
(
  cd unit
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color -var 'note=fail'
) >"$fail" 2>&1
fail_status=$?
set -e
if [[ "$fail_status" -eq 0 ]]; then
  echo "FAIL  plan -var note=fail succeeded. The validation should reject it."
  cat "$fail"
  rm -f "$fail"
  exit 1
fi
if ! grep -q 'deliberate plan failure' "$fail"; then
  echo "FAIL  the plan did not fail the note validation"
  cat "$fail"
  rm -f "$fail"
  exit 1
fi
if ! grep -q 'before hook: plan starts' "$fail"; then
  echo "FAIL  the before hook did not run before the failing plan"
  cat "$fail"
  rm -f "$fail"
  exit 1
fi
if ! grep -q 'error hook: plan failed' "$fail"; then
  echo "FAIL  the error hook did not run"
  cat "$fail"
  rm -f "$fail"
  exit 1
fi
if grep -q 'after hook: plan finished' "$fail"; then
  echo "FAIL  the after hook ran. run_on_error is false, so a failed plan skips it."
  rm -f "$fail"
  exit 1
fi
pass "error hook"
rm -f "$fail"

clean_runtime
echo "PASS  08.1 hooks"
