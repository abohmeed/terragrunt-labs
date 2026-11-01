#!/usr/bin/env bash
# 05.3 directories versus workspaces check. Re-runnable. Caches and local state are removed first.
# Run this from start/ after the TODO, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf layout/dev/.terragrunt-cache layout/prod/.terragrunt-cache layout/state \
  workspaces/.terraform workspaces/terraform.tfstate.d workspaces/marker-*.txt \
  state

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

echo "== 1. HCL and Terraform files are formatted."
terragrunt hcl fmt --check --no-color
terraform fmt -check -recursive -no-color workspaces
pass "fmt"

echo "== 2. The layout uses the local remote_state path from 05.1."
need layout/root.hcl 'backend[[:space:]]*=[[:space:]]*"local"' \
  'layout remote_state.backend should be "local"'
need layout/root.hcl 'get_parent_terragrunt_dir\(\)' \
  'layout state path should use get_parent_terragrunt_dir()'
need layout/root.hcl 'path_relative_to_include\(\)' \
  'layout state path should use path_relative_to_include()'
need layout/root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'layout root.hcl should set terraform_binary = "terraform"'
forbid layout/dev/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in layout/root.hcl'
forbid layout/prod/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in layout/root.hcl'
pass "layout config"

echo "== 3. The workspace configuration reads terraform.workspace."
need workspaces/main.tf 'environment[[:space:]]*=[[:space:]]*terraform\.workspace' \
  'set environment = terraform.workspace'
need workspaces/main.tf 'terraform\.workspace != "default"' \
  'keep the precondition that rejects the default workspace'
forbid workspaces/main.tf 'environment[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO environment'
forbid workspaces/main.tf 'environment[[:space:]]*=[[:space:]]*"(dev|prod)"' \
  'read the environment from terraform.workspace'
need workspaces/versions.tf 'backend "local"' \
  'workspaces/versions.tf should declare a local backend'
pass "workspace config"

run_layout_unit() {
  local dir="$1"
  local environment="$2"
  local prefix="$3"
  local state_file
  state_file="$(pwd)/layout/state/${environment}/terraform.tfstate"

  echo "== layout/${environment}: engine"
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

  echo "== layout/${environment}: workspace stays default"
  local show_log
  show_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color run -- workspace show
  ) >"$show_log"
  if ! grep -Eq '(^|terraform: )default$' "$show_log"; then
    echo "FAIL  ${dir}: workspace show should print default"
    cat "$show_log"
    rm -f "$show_log"
    exit 1
  fi
  pass "${dir} workspace default"
  rm -f "$show_log"

  echo "== layout/${environment}: plan and apply"
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

  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
  )
  if [[ ! -f "$state_file" ]]; then
    echo "FAIL  ${dir}: state file missing at ${state_file}"
    exit 1
  fi
  if [[ -d "${dir}/terraform.tfstate.d" ]]; then
    echo "FAIL  ${dir}: a unit directory picked up terraform.tfstate.d"
    exit 1
  fi
  pass "${dir} state file"

  local output_log
  output_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color output -no-color
  ) | tee "$output_log"
  need "$output_log" "^environment = \"${environment}\"\$" "${dir}: environment output"
  need "$output_log" "^prefix = \"${prefix}\"\$" "${dir}: prefix output"
  need "$output_log" '^note = "directory per environment"$' "${dir}: note output"
  need "$output_log" "^name = \"${prefix}-[a-z]+-[a-z]+\"\$" "${dir}: name output"
  pass "${dir} apply"
  rm -f "$output_log"

  (
    cd "$dir"
    terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
  )
  pass "${dir} destroy"
}

echo "== 4. Directory per environment."
run_layout_unit layout/dev dev dev-lab
run_layout_unit layout/prod prod prod-lab

echo "== 5. Terraform workspaces."
(
  cd workspaces
  terraform init -input=false -no-color
  echo "== default workspace is rejected"
  set +e
  terraform apply -auto-approve -input=false -no-color
  default_exit=$?
  set -e
  if [[ "$default_exit" -eq 0 ]]; then
    echo "FAIL  apply in the default workspace should fail"
    exit 1
  fi
  pass "default workspace rejected"

  terraform workspace new -no-color dev
  dev_plan="$(mktemp)"
  terraform plan -input=false -no-color | tee "$dev_plan"
  if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$dev_plan"; then
    echo "FAIL  dev workspace plan did not report 3 adds"
    rm -f "$dev_plan"
    exit 1
  fi
  rm -f "$dev_plan"
  terraform apply -auto-approve -input=false -no-color

  terraform workspace new -no-color prod
  terraform apply -auto-approve -input=false -no-color
  if [[ "$(terraform workspace show -no-color)" != "prod" ]]; then
    echo "FAIL  workspace show should print prod"
    exit 1
  fi
  pass "selected workspace is prod"
)

dev_state="workspaces/terraform.tfstate.d/dev/terraform.tfstate"
prod_state="workspaces/terraform.tfstate.d/prod/terraform.tfstate"
if [[ ! -f "$dev_state" || ! -f "$prod_state" ]]; then
  echo "FAIL  named workspace state should be under workspaces/terraform.tfstate.d/"
  find workspaces state -name 'terraform.tfstate' -print || true
  exit 1
fi
if [[ -f state/workspaces/terraform.tfstate ]]; then
  echo "FAIL  the default workspace state file should stay absent"
  exit 1
fi
pass "workspace state directories"

prod_out="$(mktemp)"
(
  cd workspaces
  terraform output -no-color
) | tee "$prod_out"
need "$prod_out" '^environment = "prod"$' "prod workspace environment"
need "$prod_out" '^note = "terraform workspace"$' "prod workspace note"
need "$prod_out" '^name = "prod-lab-[a-z]+-[a-z]+"$' "prod workspace name"
rm -f "$prod_out"

(
  cd workspaces
  terraform workspace select -no-color dev
)
dev_out="$(mktemp)"
(
  cd workspaces
  terraform output -no-color
) | tee "$dev_out"
need "$dev_out" '^environment = "dev"$' "dev workspace environment"
need "$dev_out" '^note = "terraform workspace"$' "dev workspace note"
need "$dev_out" '^name = "dev-lab-[a-z]+-[a-z]+"$' "dev workspace name"
rm -f "$dev_out"
pass "workspace outputs"

(
  cd workspaces
  terraform workspace select -no-color prod
  terraform destroy -auto-approve -input=false -no-color
  terraform workspace select -no-color dev
  terraform destroy -auto-approve -input=false -no-color
  terraform workspace select -no-color default
  terraform workspace delete -no-color prod
  terraform workspace delete -no-color dev
)
pass "workspace destroy"

rm -rf layout/dev/.terragrunt-cache layout/prod/.terragrunt-cache layout/state \
  workspaces/.terraform workspaces/terraform.tfstate.d workspaces/marker-*.txt \
  state
echo "PASS  05.3 terragrunt and workspaces"
