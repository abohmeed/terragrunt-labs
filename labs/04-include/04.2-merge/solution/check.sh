#!/usr/bin/env bash
# 04.2 merge check. Re-runnable. Each unit cache is removed first.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf shallow/.terragrunt-cache deep/.terragrunt-cache no_merge/.terragrunt-cache

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

echo "== 2. Each unit names its merge strategy."
need shallow/terragrunt.hcl 'merge_strategy[[:space:]]*=[[:space:]]*"shallow"' \
  'set merge_strategy = "shallow" in shallow/'
need deep/terragrunt.hcl 'merge_strategy[[:space:]]*=[[:space:]]*"deep"' \
  'set merge_strategy = "deep" in deep/'
need no_merge/terragrunt.hcl 'merge_strategy[[:space:]]*=[[:space:]]*"no_merge"' \
  'set merge_strategy = "no_merge" in no_merge/'
need no_merge/terragrunt.hcl 'expose[[:space:]]*=[[:space:]]*true' \
  'set expose = true on the no_merge include'
need no_merge/terragrunt.hcl 'course[[:space:]]*=[[:space:]]*include\.root\.inputs\.course' \
  'set course = include.root.inputs.course in no_merge/'
need no_merge/terragrunt.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'set terraform_binary = "terraform" in no_merge/. no_merge does not inherit it.'
forbid shallow/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary out of shallow/. The root include provides it.'
forbid deep/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary out of deep/. The root include provides it.'
pass "strategies"

assert_engine() {
  local dir="$1"
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
}

echo "== 3. Render."
render_of() {
  local dir="$1"
  local log
  log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color render
  ) | tee "$log"
  RENDER_LOG="$log"
}

render_of shallow
need "$RENDER_LOG" 'terraform_binary[[:space:]]*=[[:space:]]*"terraform"' 'shallow render: terraform_binary'
need "$RENDER_LOG" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' 'shallow render: course'
need "$RENDER_LOG" 'note[[:space:]]*=[[:space:]]*"from the unit"' 'shallow render: note'
need "$RENDER_LOG" 'prefix[[:space:]]*=[[:space:]]*"shallow"' 'shallow render: prefix'
need "$RENDER_LOG" 'labels[[:space:]]*=[[:space:]]*\["unit"\]' 'shallow render: labels replaced'
need "$RENDER_LOG" 'tier[[:space:]]*=[[:space:]]*"app"' 'shallow render: tier'
forbid "$RENDER_LOG" 'owner[[:space:]]*=' 'shallow render: nested tags.owner should be gone'
forbid "$RENDER_LOG" 'cost_center[[:space:]]*=' 'shallow render: nested tags.cost_center should be gone'
forbid "$RENDER_LOG" '"shared"' 'shallow render: the root label list should be gone'
rm -f "$RENDER_LOG"
pass "shallow render"

render_of deep
need "$RENDER_LOG" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' 'deep render: course'
need "$RENDER_LOG" 'note[[:space:]]*=[[:space:]]*"from the unit"' 'deep render: note'
need "$RENDER_LOG" 'prefix[[:space:]]*=[[:space:]]*"deep"' 'deep render: prefix'
need "$RENDER_LOG" 'owner[[:space:]]*=[[:space:]]*"platform"' 'deep render: tags.owner'
need "$RENDER_LOG" 'tier[[:space:]]*=[[:space:]]*"app"' 'deep render: tags.tier'
need "$RENDER_LOG" 'cost_center[[:space:]]*=[[:space:]]*"labs"' 'deep render: tags.cost_center'
need "$RENDER_LOG" 'labels[[:space:]]*=[[:space:]]*\["course", "shared", "unit"\]' \
  'deep render: labels should be course, shared, then unit'
rm -f "$RENDER_LOG"
pass "deep render"

render_of no_merge
need "$RENDER_LOG" 'terraform_binary[[:space:]]*=[[:space:]]*"terraform"' 'no_merge render: terraform_binary'
need "$RENDER_LOG" 'course[[:space:]]*=[[:space:]]*"terragrunt-labs"' 'no_merge render: course via expose'
need "$RENDER_LOG" 'note[[:space:]]*=[[:space:]]*"from the unit"' 'no_merge render: note'
need "$RENDER_LOG" 'prefix[[:space:]]*=[[:space:]]*"no-merge"' 'no_merge render: prefix'
need "$RENDER_LOG" 'labels[[:space:]]*=[[:space:]]*\["unit"\]' 'no_merge render: labels'
need "$RENDER_LOG" 'tier[[:space:]]*=[[:space:]]*"app"' 'no_merge render: tier'
forbid "$RENDER_LOG" 'owner[[:space:]]*=' 'no_merge render: root tags should not merge'
forbid "$RENDER_LOG" 'cost_center[[:space:]]*=' 'no_merge render: root tags should not merge'
forbid "$RENDER_LOG" 'note[[:space:]]*=[[:space:]]*"from root"' 'no_merge render: root note should not merge'
forbid "$RENDER_LOG" '"shared"' 'no_merge render: root labels should not merge'
rm -f "$RENDER_LOG"
pass "no_merge render"

run_unit() {
  local dir="$1"
  local prefix="$2"
  local owner="$3"
  local cost="$4"
  local labels="$5"

  echo "== ${dir}: engine"
  assert_engine "$dir"

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
  need "$output_log" "^prefix = \"${prefix}\"\$" "${dir}: prefix output"
  need "$output_log" '^note = "from the unit"$' "${dir}: note output"
  need "$output_log" "^owner = \"${owner}\"\$" "${dir}: owner output"
  need "$output_log" '^tier = "app"$' "${dir}: tier output"
  need "$output_log" "^cost_center = \"${cost}\"\$" "${dir}: cost_center output"
  need "$output_log" "^labels = \"${labels}\"\$" "${dir}: labels output"
  need "$output_log" "^name = \"${prefix}-[a-z]+-[a-z]+\"\$" "${dir}: name output"
  pass "${dir} apply"
  rm -f "$output_log"
  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
  )
  pass "${dir} destroy"
}

echo "== 4. Apply each strategy."
run_unit shallow shallow "" "" unit
run_unit deep deep platform labs "course,shared,unit"
run_unit no_merge no-merge "" "" unit

echo "PASS  04.2 merge"
