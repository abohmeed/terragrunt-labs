#!/usr/bin/env bash
# 03.1 source check. Re-runnable. The cache is removed at the start.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf .terragrunt-cache

pass() {
  echo "PASS  $*"
}

echo "== 1. Engine. terraform_binary selects Terraform, even if tofu is on PATH."
version_log="$(mktemp)"
terragrunt --no-color run -- version 2>&1 | tee "$version_log"
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  terragrunt run -- version did not report Terraform 1.17.x"
  rm -f "$version_log"
  exit 1
fi
if grep -q "OpenTofu" "$version_log"; then
  echo "FAIL  OpenTofu ran. terraform_binary should select Terraform."
  rm -f "$version_log"
  exit 1
fi
pass "engine is Terraform 1.17.x"
rm -f "$version_log"

echo "== 2. Unit source copies this directory. Module source is ../label."
if ! grep -q 'get_terragrunt_dir()}//modules/service' terragrunt.hcl; then
  echo "FAIL  set terraform.source to \${get_terragrunt_dir()}//modules/service"
  exit 1
fi
if ! grep -q 'source = "../label"' modules/service/main.tf; then
  echo 'FAIL  set the label module source to "../label"'
  exit 1
fi
pass "sources"

echo "== 3. Plan."
plan_log="$(mktemp)"
terragrunt --no-color --non-interactive run -- plan -input=false -no-color 2>&1 | tee "$plan_log"
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  plan did not report 3 adds"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"

echo "== 4. Staged copy: ../label sits next to the working directory."
tfdir="$(find .terragrunt-cache -type d -name .terraform -print -quit)"
if [[ -z "$tfdir" ]]; then
  echo "FAIL  Terraform working directory was not created"
  exit 1
fi
workdir="$(dirname "$tfdir")"
if [[ ! -f "$workdir/main.tf" ]]; then
  echo "FAIL  working directory has no main.tf: $workdir"
  exit 1
fi
if [[ ! -f "$workdir/../label/main.tf" ]]; then
  echo "FAIL  ../label is missing beside the working directory: $workdir"
  exit 1
fi
if ! grep -q 'source = "../label"' "$workdir/main.tf"; then
  echo "FAIL  staged main.tf does not call ../label"
  exit 1
fi
pass "working directory: $workdir"
pass "label module: $workdir/../label/main.tf"

echo "== 5. Inputs match the root module variables."
terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
pass "inputs"

echo "== 6. Apply, output, destroy."
terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
output_log="$(mktemp)"
terragrunt --no-color output -no-color | tee "$output_log"
if ! grep -Eq 'name = "lab-[a-z]+-[a-z]+"' "$output_log"; then
  echo "FAIL  output name was not a lab- pet name"
  rm -f "$output_log"
  exit 1
fi
pass "apply"
rm -f "$output_log"
terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
pass "destroy"

echo "PASS  03.1 source"
