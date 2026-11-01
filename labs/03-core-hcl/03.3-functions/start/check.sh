#!/usr/bin/env bash
# 03.3 functions check. Re-runnable. The cache is removed at the start.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf dev/unit/.terragrunt-cache

pass() {
  echo "PASS  $*"
}

unit() {
  (cd dev/unit && "$@")
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Engine."
version_log="$(mktemp)"
unit terragrunt --no-color run -- version 2>&1 | tee "$version_log"
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

echo "== 3. Inputs match the module variables."
unit terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
pass "inputs"

expect_output() {
  local note="$1"
  local output_log
  output_log="$(mktemp)"
  unit terragrunt --no-color output -no-color | tee "$output_log"
  grep -qx 'course = "terragrunt-labs"' "$output_log"
  grep -qx 'region = "local"' "$output_log"
  grep -qx 'environment = "dev"' "$output_log"
  grep -qx 'prefix = "dev-local-lab"' "$output_log"
  grep -qx 'unit_path = "dev/unit"' "$output_log"
  grep -qx "note = \"${note}\"" "$output_log"
  grep -Eq '^name = "dev-local-lab-[a-z]+-[a-z]+"$' "$output_log"
  rm -f "$output_log"
}

echo "== 4. Apply with LAB_NOTE unset."
(
  cd dev/unit
  env -u LAB_NOTE terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
expect_output "offline functions lab"
pass "default note"
(
  cd dev/unit
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "destroy default"

echo "== 5. Apply with LAB_NOTE set."
rm -rf dev/unit/.terragrunt-cache
(
  cd dev/unit
  LAB_NOTE="from the environment" terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
expect_output "from the environment"
pass "LAB_NOTE"
(
  cd dev/unit
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "destroy LAB_NOTE"

echo "PASS  03.3 functions"
