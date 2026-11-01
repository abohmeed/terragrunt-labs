#!/usr/bin/env bash
# 04.4 environment layout check. Re-runnable. Each unit cache is removed first.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf sandbox/local/dev/record/.terragrunt-cache sandbox/local/prod/record/.terragrunt-cache

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

count_of() {
  local pattern="$1"
  local file="$2"
  grep -cE "$pattern" "$file" || true
}

dev_unit="sandbox/local/dev/record"
prod_unit="sandbox/local/prod/record"

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. dev and prod units are the same file."
if ! cmp -s "${dev_unit}/terragrunt.hcl" "${prod_unit}/terragrunt.hcl"; then
  echo "FAIL  keep dev/record/terragrunt.hcl and prod/record/terragrunt.hcl identical. Differences belong in env.hcl."
  exit 1
fi
pass "identical units"

echo "== 3. Four includes. Account, region, and env use no_merge."
unit_hcl="${dev_unit}/terragrunt.hcl"
need "$unit_hcl" 'include "root"' 'add include "root"'
need "$unit_hcl" 'include "account"' 'add include "account"'
need "$unit_hcl" 'include "region"' 'add include "region"'
need "$unit_hcl" 'include "env"' 'add include "env"'
need "$unit_hcl" 'include\.root\.locals\.course' 'set course from include.root.locals.course'
need "$unit_hcl" 'include\.account\.locals\.account_name' 'set account from include.account.locals.account_name'
need "$unit_hcl" 'include\.region\.locals\.region' 'set region from include.region.locals.region'
need "$unit_hcl" 'include\.env\.locals\.environment' 'set environment from include.env.locals.environment'
need "$unit_hcl" 'include\.env\.locals\.prefix_root' 'read prefix_root from include.env.locals'
need "$unit_hcl" 'path_relative_to_include\("root"\)' 'set unit_path with path_relative_to_include("root")'
need "$unit_hcl" 'dirname\(find_in_parent_folders\("root.hcl"\)\)' \
  'point terraform.source at modules/record next to root.hcl'
forbid "$unit_hcl" '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl. The root include merges it.'

expose_count="$(count_of 'expose[[:space:]]*=[[:space:]]*true' "$unit_hcl")"
if [[ "$expose_count" -ne 4 ]]; then
  echo "FAIL  expose all four includes (found ${expose_count})"
  exit 1
fi
nomerge_count="$(count_of 'merge_strategy[[:space:]]*=[[:space:]]*"no_merge"' "$unit_hcl")"
if [[ "$nomerge_count" -ne 3 ]]; then
  echo "FAIL  set no_merge on the account, region, and env includes only (found ${nomerge_count})"
  exit 1
fi
pass "includes"

run_unit() {
  local dir="$1"
  local environment="$2"
  local prefix="$3"
  local unit_path="$4"

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
    echo "FAIL  ${dir}: OpenTofu ran. The root include should merge terraform_binary."
    rm -f "$version_log"
    exit 1
  fi
  pass "${dir} engine"
  rm -f "$version_log"

  echo "== ${dir}: render"
  local render_log
  render_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color render
  ) | tee "$render_log"
  need "$render_log" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' "${dir} render: course"
  need "$render_log" 'account[[:space:]]*=[[:space:]]*"sandbox"' "${dir} render: account"
  need "$render_log" 'region[[:space:]]*=[[:space:]]*"local"' "${dir} render: region"
  need "$render_log" "environment[[:space:]]*=[[:space:]]*\"${environment}\"" "${dir} render: environment"
  need "$render_log" "prefix[[:space:]]*=[[:space:]]*\"${prefix}\"" "${dir} render: prefix"
  need "$render_log" "unit_path[[:space:]]*=[[:space:]]*\"${unit_path}\"" "${dir} render: unit_path"
  pass "${dir} render"
  rm -f "$render_log"

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
  need "$output_log" '^course = "terragrunt-labs"$' "${dir}: course output"
  need "$output_log" '^account = "sandbox"$' "${dir}: account output"
  need "$output_log" '^region = "local"$' "${dir}: region output"
  need "$output_log" "^environment = \"${environment}\"\$" "${dir}: environment output"
  need "$output_log" "^prefix = \"${prefix}\"\$" "${dir}: prefix output"
  need "$output_log" "^unit_path = \"${unit_path}\"\$" "${dir}: unit_path output"
  need "$output_log" "^name = \"${prefix}-[a-z]+-[a-z]+\"\$" "${dir}: name output"
  pass "${dir} apply"
  rm -f "$output_log"
  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
  )
  pass "${dir} destroy"
}

echo "== 4. Dev and prod."
run_unit "$dev_unit" dev sandbox-dev-lab "sandbox/local/dev/record"
run_unit "$prod_unit" prod sandbox-prod-lab "sandbox/local/prod/record"

echo "PASS  04.4 environment layout"
