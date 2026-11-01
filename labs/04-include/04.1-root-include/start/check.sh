#!/usr/bin/env bash
# 04.1 root include check. Re-runnable. The cache is removed at the start.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf unit/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

need() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! grep -Eq "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

forbid() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if grep -Eq "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. The unit includes root.hcl. terraform_binary stays in the root."
need unit/terragrunt.hcl 'find_in_parent_folders\("root.hcl"\)' \
  'set the include path to find_in_parent_folders("root.hcl")'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid unit/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl. The unit inherits it.'
pass "include"

echo "== 3. Engine."
version_log="$(mktemp)"
(cd unit && terragrunt --no-color run -- version) 2>&1 | tee "$version_log"
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
  rm -f "$version_log"
  exit 1
fi
if grep -q "OpenTofu" "$version_log"; then
  echo "FAIL  OpenTofu ran. The included root.hcl should set terraform_binary."
  rm -f "$version_log"
  exit 1
fi
pass "engine is Terraform 1.17.x"
rm -f "$version_log"

echo "== 4. Render. Root keys merge, and the unit overrides note."
render_log="$(mktemp)"
(cd unit && terragrunt --no-color render) | tee "$render_log"
need "$render_log" 'terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'render is missing terraform_binary from root.hcl'
need "$render_log" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' \
  'render is missing course from root.hcl'
need "$render_log" 'prefix[[:space:]]*=[[:space:]]*"lab"' \
  'render is missing prefix = "lab"'
need "$render_log" 'note[[:space:]]*=[[:space:]]*"from the unit"' \
  'render is missing note = "from the unit"'
forbid "$render_log" 'note[[:space:]]*=[[:space:]]*"from root"' \
  'the unit should override note'
pass "render"
rm -f "$render_log"

echo "== 5. Inputs match the module variables."
(cd unit && terragrunt hcl validate --inputs --strict --tf-path terraform --no-color)
pass "inputs"

echo "== 6. Plan, apply, output, destroy."
plan_log="$(mktemp)"
(cd unit && terragrunt --no-color --non-interactive run -- plan -input=false -no-color) 2>&1 | tee "$plan_log"
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  plan did not report 3 adds"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"

(cd unit && terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color)
output_log="$(mktemp)"
(cd unit && terragrunt --no-color output -no-color) | tee "$output_log"
need "$output_log" '^course = "terragrunt-labs"$' 'course output'
need "$output_log" '^prefix = "lab"$' 'prefix output'
need "$output_log" '^note = "from the unit"$' 'note output'
need "$output_log" '^name = "lab-[a-z]+-[a-z]+"$' 'name output'
pass "apply"
rm -f "$output_log"

(cd unit && terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color)
pass "destroy"

echo "PASS  04.1 root include"
