#!/usr/bin/env bash
# 04.3 multiple includes check. Re-runnable. The cache is removed at the start.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf dev/unit/.terragrunt-cache

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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Three exposed includes. Region and env use no_merge."
unit_hcl="dev/unit/terragrunt.hcl"
need "$unit_hcl" 'include "root"' 'add include "root"'
need "$unit_hcl" 'include "region"' 'add include "region"'
need "$unit_hcl" 'include "env"' 'add include "env"'
need "$unit_hcl" 'include\.root\.locals\.course' 'set course from include.root.locals.course'
need "$unit_hcl" 'include\.region\.locals\.region' 'set region from include.region.locals.region'
need "$unit_hcl" 'include\.env\.locals\.environment' 'set environment from include.env.locals.environment'
need "$unit_hcl" 'include\.env\.locals\.prefix_root' 'read prefix_root from include.env.locals'
need "$unit_hcl" 'path_relative_to_include\("root"\)' 'set unit_path with path_relative_to_include("root")'
forbid "$unit_hcl" '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl. The root include merges it.'

expose_count="$(count_of 'expose[[:space:]]*=[[:space:]]*true' "$unit_hcl")"
if [[ "$expose_count" -ne 3 ]]; then
  echo "FAIL  expose all three includes (found ${expose_count})"
  exit 1
fi
nomerge_count="$(count_of 'merge_strategy[[:space:]]*=[[:space:]]*"no_merge"' "$unit_hcl")"
if [[ "$nomerge_count" -ne 2 ]]; then
  echo "FAIL  set no_merge on the region and env includes only (found ${nomerge_count})"
  exit 1
fi
pass "includes"

echo "== 3. Engine."
version_log="$(mktemp)"
(cd dev/unit && terragrunt --no-color run -- version) 2>&1 | tee "$version_log"
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
  rm -f "$version_log"
  exit 1
fi
if grep -q "OpenTofu" "$version_log"; then
  echo "FAIL  OpenTofu ran. The root include should merge terraform_binary."
  rm -f "$version_log"
  exit 1
fi
pass "engine is Terraform 1.17.x"
rm -f "$version_log"

echo "== 4. Render. Each value comes from the include that owns it."
render_log="$(mktemp)"
(cd dev/unit && terragrunt --no-color render) | tee "$render_log"
need "$render_log" 'terraform_binary[[:space:]]*=[[:space:]]*"terraform"' 'render: terraform_binary'
need "$render_log" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' 'render: course'
need "$render_log" 'region[[:space:]]*=[[:space:]]*"local"' 'render: region'
need "$render_log" 'environment[[:space:]]*=[[:space:]]*"dev"' 'render: environment'
need "$render_log" 'prefix[[:space:]]*=[[:space:]]*"dev-local-lab"' 'render: prefix'
need "$render_log" 'unit_path[[:space:]]*=[[:space:]]*"dev/unit"' 'render: unit_path'
need "$render_log" 'note[[:space:]]*=[[:space:]]*"exposed includes"' 'render: note'
pass "render"
rm -f "$render_log"

echo "== 5. Inputs match the module variables."
(cd dev/unit && terragrunt hcl validate --inputs --strict --tf-path terraform --no-color)
pass "inputs"

echo "== 6. Plan, apply, output, destroy."
plan_log="$(mktemp)"
(cd dev/unit && terragrunt --no-color --non-interactive run -- plan -input=false -no-color) 2>&1 | tee "$plan_log"
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  plan did not report 3 adds"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"

(cd dev/unit && terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color)
output_log="$(mktemp)"
(cd dev/unit && terragrunt --no-color output -no-color) | tee "$output_log"
need "$output_log" '^course = "terragrunt-labs"$' 'course output'
need "$output_log" '^region = "local"$' 'region output'
need "$output_log" '^environment = "dev"$' 'environment output'
need "$output_log" '^prefix = "dev-local-lab"$' 'prefix output'
need "$output_log" '^unit_path = "dev/unit"$' 'unit_path output'
need "$output_log" '^note = "exposed includes"$' 'note output'
need "$output_log" '^name = "dev-local-lab-[a-z]+-[a-z]+"$' 'name output'
pass "apply"
rm -f "$output_log"

(cd dev/unit && terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color)
pass "destroy"

echo "PASS  04.3 multiple includes"
