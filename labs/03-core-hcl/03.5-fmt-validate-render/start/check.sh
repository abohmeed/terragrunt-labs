#!/usr/bin/env bash
# 03.5 fmt, validate, and render. Re-runnable. The cache is removed at the start.
# Run this from start/ or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf .terragrunt-cache terragrunt.rendered.hcl terragrunt.rendered.json

pass() {
  echo "PASS  $*"
}

echo "== 1. Format HCL under this directory."
terragrunt hcl fmt --diff --no-color
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Validate HCL."
terragrunt hcl validate --no-color
pass "validate"

echo "== 3. Validate inputs with Terraform, not tofu."
# hcl validate --inputs looks up tofu unless --tf-path is set.
# terraform_binary in the unit does not change this command.
terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
pass "validate inputs"

echo "== 4. Render. Locals are already resolved."
render_log="$(mktemp)"
terragrunt --no-color render | tee "$render_log"
if grep -q 'local\.' "$render_log"; then
  echo "FAIL  render still contains a local reference"
  rm -f "$render_log"
  exit 1
fi
grep -Eq 'environment[[:space:]]*=[[:space:]]*"dev"' "$render_log"
grep -Eq 'prefix[[:space:]]*=[[:space:]]*"lab"' "$render_log"
grep -Eq 'note[[:space:]]*=[[:space:]]*"rendered offline"' "$render_log"
pass "render"
rm -f "$render_log"

echo "== 5. Render JSON."
json_log="$(mktemp)"
terragrunt --no-color render --format json >"$json_log"
if ! grep -Eq '"environment"[[:space:]]*:[[:space:]]*"dev"' "$json_log"; then
  echo "FAIL  JSON render did not resolve environment"
  cat "$json_log"
  rm -f "$json_log"
  exit 1
fi
if ! grep -Eq '"note"[[:space:]]*:[[:space:]]*"rendered offline"' "$json_log"; then
  echo "FAIL  JSON render did not resolve note"
  cat "$json_log"
  rm -f "$json_log"
  exit 1
fi
pass "render json"
rm -f "$json_log"

echo "== 6. Engine."
version_log="$(mktemp)"
terragrunt --no-color run -- version 2>&1 | tee "$version_log"
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
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

echo "== 7. Plan, apply, output, destroy."
plan_log="$(mktemp)"
terragrunt --no-color --non-interactive run -- plan -input=false -no-color 2>&1 | tee "$plan_log"
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  plan did not report 3 adds"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"
terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
output_log="$(mktemp)"
terragrunt --no-color output -no-color | tee "$output_log"
if ! grep -qx 'environment = "dev"' "$output_log"; then
  echo "FAIL  environment output"
  rm -f "$output_log"
  exit 1
fi
if ! grep -Eq '^name = "lab-[a-z]+-[a-z]+"$' "$output_log"; then
  echo "FAIL  name output"
  rm -f "$output_log"
  exit 1
fi
if ! grep -qx 'note = "rendered offline"' "$output_log"; then
  echo "FAIL  note output"
  rm -f "$output_log"
  exit 1
fi
pass "apply"
rm -f "$output_log"
terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
pass "destroy"

echo "PASS  03.5 fmt, validate, and render"
