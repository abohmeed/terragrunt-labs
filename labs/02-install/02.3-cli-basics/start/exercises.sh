#!/usr/bin/env bash
# 02.3 CLI exercises. Re-runnable. The cache is removed at the start.
# Run this from start/ after reading the lecture README, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf .terragrunt-cache

pass() {
  echo "PASS  $*"
}

expect_fail() {
  local pattern="$1"
  shift
  local log status
  log="$(mktemp)"
  set +e
  "$@" >"$log" 2>&1
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL  expected a non-zero exit: $*"
    cat "$log"
    rm -f "$log"
    exit 1
  fi
  if ! grep -Eq "$pattern" "$log"; then
    echo "FAIL  output did not match /${pattern}/: $*"
    cat "$log"
    rm -f "$log"
    exit 1
  fi
  pass "rejected: $*"
  rm -f "$log"
}

expect_plan() {
  local log
  log="$(mktemp)"
  "$@" 2>&1 | tee "$log"
  if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$log"; then
    echo "FAIL  plan did not report 3 adds: $*"
    rm -f "$log"
    exit 1
  fi
  pass "plan: $*"
  rm -f "$log"
}

echo "== 1. Engine. terraform_binary selects Terraform, even if tofu is on PATH."
version_log="$(mktemp)"
terragrunt --no-color run -- version 2>&1 | tee "$version_log"
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  terragrunt run -- version did not report Terraform 1.17.x"
  rm -f "$version_log"
  exit 1
fi
pass "engine is Terraform 1.17.x"
rm -f "$version_log"

echo "== 2. Explicit init."
terragrunt --no-color run -- init -input=false
pass "init"

echo "== 3. terragrunt run plan (no extra Terraform flags)."
expect_plan terragrunt --no-color run plan

echo "== 4. Same plan, Terraform flags after --."
expect_plan terragrunt --no-color run -- plan -input=false -no-color

echo "== 5. Shortcut: terragrunt plan."
expect_plan terragrunt --no-color plan -input=false -no-color

echo "== 6. Terraform flags on 'run' need the -- separator."
expect_fail 'not a Terragrunt flag' terragrunt --no-color run plan -input=false

echo "== 7. The 0.x --terragrunt- prefix is rejected."
expect_fail 'terragrunt-non-interactive' terragrunt --no-color --terragrunt-non-interactive plan

echo "== 8. Apply. --non-interactive answers Terragrunt prompts. -auto-approve answers Terraform."
terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
pass "apply"

echo "== 9. Shortcut: terragrunt output."
output_log="$(mktemp)"
terragrunt --no-color output -no-color | tee "$output_log"
if ! grep -Eq 'name = "lab-[a-z]+-[a-z]+"' "$output_log"; then
  echo "FAIL  output name was not a lab- pet name"
  rm -f "$output_log"
  exit 1
fi
pass "output"
rm -f "$output_log"

echo "== 10. Working copy Terragrunt created."
cache_tf="$(find .terragrunt-cache -type d -name .terraform -print -quit)"
if [[ -z "$cache_tf" || ! -f "$(dirname "$cache_tf")/main.tf" ]]; then
  echo "FAIL  Terraform working directory was not created under .terragrunt-cache"
  exit 1
fi
pass "Terraform working directory: $(dirname "$cache_tf")"

echo "== 11. workspace is not a shortcut. run -- forwards it."
expect_fail 'unknown command: "workspace"' terragrunt --no-color workspace list
terragrunt --no-color run -- workspace list
pass "workspace list via run"

echo "== 12. Destroy with the same 1.x flags."
terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
pass "destroy"

echo "PASS  02.3 exercises"
