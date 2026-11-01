#!/usr/bin/env bash
# 06.2 mock outputs check. Re-runnable. The cache is removed first.
# Run this from start/ after the TODO, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache service/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Mocks cover plan, and apply still requires the real output."
need service/terragrunt.hcl 'dependency[[:space:]]+"network"' \
  'keep the dependency "network" block in service/'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'keep config_path = "../network"'
need service/terragrunt.hcl 'mock_outputs[[:space:]]*=' \
  'set mock_outputs on the network dependency'
need service/terragrunt.hcl 'name[[:space:]]*=[[:space:]]*"mock-network-name"' \
  'mock the name output as "mock-network-name"'
need service/terragrunt.hcl 'mock_outputs_allowed_terraform_commands[[:space:]]*=[[:space:]]*\[[^]]*validate[^]]*plan' \
  'allow mocks for validate and plan'
forbid service/terragrunt.hcl 'mock_outputs_allowed_terraform_commands[[:space:]]*=[[:space:]]*\[[^]]*apply' \
  'do not allow mocks for apply'
need service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
  'keep note = dependency.network.outputs.name'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid service/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
pass "mock outputs"

echo "== 3. Engine."
version_log="$(mktemp)"
(
  cd network
  terragrunt --no-color run -- version
) >"$version_log" 2>&1
if ! grep -q "Terraform v1\.17\." "$version_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
  cat "$version_log"
  rm -f "$version_log"
  exit 1
fi
if grep -q "OpenTofu" "$version_log"; then
  echo "FAIL  OpenTofu ran. terraform_binary should select Terraform."
  rm -f "$version_log"
  exit 1
fi
pass "engine"
rm -f "$version_log"

echo "== 4. Plan service before network is applied."
plan_log="$(mktemp)"
(
  cd service
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  cold service plan did not report 3 adds"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -Fq '"mock-network-name"' "$plan_log"; then
  echo "FAIL  cold service plan did not use mock-network-name"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "cold plan uses the mock"
rm -f "$plan_log"

echo "== 5. Apply service is refused while network has no outputs."
apply_log="$(mktemp)"
set +e
(
  cd service
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
) >"$apply_log" 2>&1
apply_status=$?
set -e
if [[ "$apply_status" -eq 0 ]]; then
  echo "FAIL  service apply ran on the mock. apply is not in the allow list."
  rm -f "$apply_log"
  exit 1
fi
if ! grep -q "detected no outputs" "$apply_log"; then
  echo "FAIL  service apply failed for a reason other than the missing network output"
  cat "$apply_log"
  rm -f "$apply_log"
  exit 1
fi
pass "apply refused without network"
rm -f "$apply_log"
rm -rf service/.terragrunt-cache

echo "== 6. After network is applied, service uses the real name."
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

real_plan="$(mktemp)"
(
  cd service
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$real_plan" 2>&1
if ! grep -Fq "\"${net_name}\"" "$real_plan"; then
  echo "FAIL  service plan did not replace the mock with ${net_name}"
  cat "$real_plan"
  rm -f "$real_plan"
  exit 1
fi
if grep -Fq '"mock-network-name"' "$real_plan"; then
  echo "FAIL  service plan still contains the mock after network was applied"
  cat "$real_plan"
  rm -f "$real_plan"
  exit 1
fi
pass "plan uses the real output"
rm -f "$real_plan"

(
  cd service
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
svc_note="$(
  cd service
  terragrunt --no-color output -raw note
)"
if [[ "$svc_note" != "$net_name" ]]; then
  echo "FAIL  service note '${svc_note}' is not network name '${net_name}'"
  exit 1
fi
pass "applied note is the network name"

echo "== 7. Inputs match the module variables."
(
  cd service
  terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
)
pass "inputs"

echo "== 8. Destroy service before network."
(
  cd service
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
(
  cd network
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "destroy"

rm -rf network/.terragrunt-cache service/.terragrunt-cache
echo "PASS  06.2 mock outputs"
