#!/usr/bin/env bash
# 06.1 dependency check. Re-runnable. The cache is removed first.
# Run this from start/ after the TODO, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache service/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

# Match HCL code only. Lecture comments name the same tokens.
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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. service reads the network name. This lecture has no mocks."
need service/terragrunt.hcl 'dependency[[:space:]]+"network"' \
  'add a dependency "network" block in service/'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'set config_path = "../network" in service/'
need service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
  'set note = dependency.network.outputs.name in service/'
forbid service/terragrunt.hcl 'mock_outputs' \
  'leave mock_outputs out of this lecture'
forbid service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO note'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid network/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid service/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
pass "dependency block"

echo "== 3. Engine."
assert_engine network

echo "== 4. service cannot plan before network is applied."
early="$(mktemp)"
set +e
(
  cd service
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$early" 2>&1
early_status=$?
set -e
if [[ "$early_status" -eq 0 ]]; then
  echo "FAIL  service planned before network was applied"
  rm -f "$early"
  exit 1
fi
if ! grep -q "detected no outputs" "$early"; then
  echo "FAIL  service plan failed for a reason other than the missing network output"
  cat "$early"
  rm -f "$early"
  exit 1
fi
pass "plan blocked until network is applied"
rm -f "$early"
rm -rf service/.terragrunt-cache

echo "== 5. Apply network, then plan and apply service."
(
  cd network
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
net_name="$(
  cd network
  terragrunt --no-color output -raw name
)"
if [[ ! "$net_name" =~ ^net-[a-z]+-[a-z]+$ ]]; then
  echo "FAIL  network name was '${net_name}'"
  exit 1
fi
pass "network apply (${net_name})"

plan_log="$(mktemp)"
(
  cd service
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  service plan did not report 3 adds"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -Fq "\"${net_name}\"" "$plan_log"; then
  echo "FAIL  service plan did not use network name ${net_name}"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "service plan uses the network output"
rm -f "$plan_log"

(
  cd service
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
svc_note="$(
  cd service
  terragrunt --no-color output -raw note
)"
svc_name="$(
  cd service
  terragrunt --no-color output -raw name
)"
if [[ "$svc_note" != "$net_name" ]]; then
  echo "FAIL  service note '${svc_note}' is not network name '${net_name}'"
  exit 1
fi
if [[ ! "$svc_name" =~ ^svc-[a-z]+-[a-z]+$ ]]; then
  echo "FAIL  service name was '${svc_name}'"
  exit 1
fi
pass "service note is the network name"

echo "== 6. Inputs match the module variables."
(
  cd service
  terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
)
pass "inputs"

assert_engine service

echo "== 7. Destroy the service unit before the network unit."
(
  cd service
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "service destroy"
(
  cd network
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "network destroy"

rm -rf network/.terragrunt-cache service/.terragrunt-cache
echo "PASS  06.1 dependency"
