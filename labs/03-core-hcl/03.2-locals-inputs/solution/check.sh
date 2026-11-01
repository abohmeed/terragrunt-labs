#!/usr/bin/env bash
# 03.2 locals and inputs check. Re-runnable. Each unit cache is removed first.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf dev/.terragrunt-cache prod/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

run_unit() {
  local dir="$1"
  local environment="$2"
  local prefix="$3"

  echo "== ${dir}: engine"
  local version_log
  version_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color run -- version
  ) 2>&1 | tee "$version_log"
  if ! grep -q "Terraform v1\.17\." "$version_log"; then
    echo "FAIL  ${dir}: engine was not Terraform 1.17.x"
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

  echo "== ${dir}: inputs match the module variables."
  (
    cd "$dir"
    terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
  )
  pass "${dir} inputs"

  echo "== ${dir}: plan"
  local plan_log
  plan_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- plan -input=false -no-color
  ) 2>&1 | tee "$plan_log"
  if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
    echo "FAIL  ${dir}: plan did not report 3 adds"
    rm -f "$plan_log"
    exit 1
  fi
  if ! grep -Eq "prefix[[:space:]]*=[[:space:]]*\"${prefix}\"" "$plan_log"; then
    echo "FAIL  ${dir}: plan did not set prefix ${prefix}"
    rm -f "$plan_log"
    exit 1
  fi
  pass "${dir} plan"
  rm -f "$plan_log"

  echo "== ${dir}: apply, output, destroy"
  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
  )
  local output_log
  output_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color output -no-color
  ) | tee "$output_log"
  if ! grep -qx "environment = \"${environment}\"" "$output_log"; then
    echo "FAIL  ${dir}: environment output"
    rm -f "$output_log"
    exit 1
  fi
  if ! grep -Eq "^name = \"${prefix}-[a-z]+-[a-z]+\"$" "$output_log"; then
    echo "FAIL  ${dir}: name output"
    rm -f "$output_log"
    exit 1
  fi
  if ! grep -qx 'note = "offline locals and inputs"' "$output_log"; then
    echo "FAIL  ${dir}: note output"
    rm -f "$output_log"
    exit 1
  fi
  pass "${dir} apply"
  rm -f "$output_log"
  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
  )
  pass "${dir} destroy"
}

run_unit dev dev dev-lab
run_unit prod prod prod-lab

echo "PASS  03.2 locals and inputs"
