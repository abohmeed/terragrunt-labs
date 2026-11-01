#!/usr/bin/env bash
# 12.1 switch to OpenTofu. Re-runnable. The cache is removed first.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf unit/.terragrunt-cache unit/.terraform

pass() {
  echo "PASS  $*"
}

code_grep() {
  local file="$1"
  local pattern="$2"
  grep -E -- "$pattern" "$file" | grep -Eqv -- '^[[:space:]]*#'
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

section() {
  local log="$1"
  local name="$2"
  awk -v name="$name" '
    $0 == "== " name " ==" { capture = 1; next }
    capture && $0 ~ /^== / { exit }
    capture { print }
  ' "$log"
}

echo "== 1. Terragrunt 1.2.x, OpenTofu 1.13.x, and formatted HCL."
tg_log="$(mktemp)"
terragrunt --version >"$tg_log" 2>&1
if ! grep -q "v1\\.2\\." "$tg_log"; then
  echo "FAIL  terragrunt was not 1.2.x"
  cat "$tg_log"
  rm -f "$tg_log"
  exit 1
fi
pass "terragrunt 1.2.x"
rm -f "$tg_log"
tofu_log="$(mktemp)"
tofu version >"$tofu_log" 2>&1
if ! grep -q "OpenTofu v1\\.13\\." "$tofu_log"; then
  echo "FAIL  tofu was not OpenTofu 1.13.x"
  cat "$tofu_log"
  rm -f "$tofu_log"
  exit 1
fi
pass "opentofu 1.13.x"
rm -f "$tofu_log"
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. The unit stays on tofu unless a flag or variable overrides it."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"tofu"' \
  'root.hcl should set terraform_binary = "tofu"'
forbid root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'change terraform_binary from terraform to tofu'
need unit/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"switched to tofu"' \
  'the note should stay switched to tofu'
need modules/record/versions.tf '>= 1\.13\.0, < 1\.18\.0' \
  'required_version should accept OpenTofu 1.13 and Terraform 1.17'
if ! grep -q 'registry.opentofu.org/hashicorp/random' unit/.terraform.lock.hcl; then
  echo "FAIL  the lock file should select registry.opentofu.org"
  exit 1
fi
pass "attribute and lock file"

echo "== 3. scripts/engines.sh shows attribute, --tf-path, and TG_TF_PATH."
need scripts/engines.sh 'run -- version' \
  'engines.sh should run version'
need scripts/engines.sh '--tf-path terraform' \
  'engines.sh should pass --tf-path terraform'
need scripts/engines.sh 'TG_TF_PATH=terraform' \
  'engines.sh should set TG_TF_PATH=terraform for one command'
if [[ ! -x scripts/engines.sh ]]; then
  echo "FAIL  scripts/engines.sh should be executable"
  exit 1
fi
engine_log="$(mktemp)"
set +e
./scripts/engines.sh >"$engine_log" 2>&1
engine_status=$?
set -e
if [[ "$engine_status" -ne 0 ]]; then
  echo "FAIL  scripts/engines.sh exited ${engine_status}"
  cat "$engine_log"
  rm -f "$engine_log"
  exit 1
fi
attribute="$(section "$engine_log" attribute)"
flag="$(section "$engine_log" flag)"
env="$(section "$engine_log" env)"
if ! grep -q "OpenTofu v1\\.13\\." <<<"$attribute"; then
  echo "FAIL  the attribute should select OpenTofu 1.13.x"
  cat "$engine_log"
  rm -f "$engine_log"
  exit 1
fi
if grep -q "Terraform v" <<<"$attribute"; then
  echo "FAIL  the attribute run printed Terraform. terraform_binary should be tofu."
  rm -f "$engine_log"
  exit 1
fi
if ! grep -q "Terraform v1\\.17\\." <<<"$flag"; then
  echo "FAIL  --tf-path terraform should select Terraform 1.17.x"
  cat "$engine_log"
  rm -f "$engine_log"
  exit 1
fi
if grep -q "OpenTofu v" <<<"$flag"; then
  echo "FAIL  --tf-path terraform still ran OpenTofu"
  rm -f "$engine_log"
  exit 1
fi
if ! grep -q "Terraform v1\\.17\\." <<<"$env"; then
  echo "FAIL  TG_TF_PATH=terraform should select Terraform 1.17.x"
  cat "$engine_log"
  rm -f "$engine_log"
  exit 1
fi
if grep -q "OpenTofu v" <<<"$env"; then
  echo "FAIL  TG_TF_PATH=terraform still ran OpenTofu"
  rm -f "$engine_log"
  exit 1
fi
pass "selectors"
rm -f "$engine_log"

echo "== 4. Apply with the attribute, then destroy."
terragrunt --no-color --non-interactive --working-dir unit run -- apply -auto-approve -input=false -no-color
note="$(cd unit && terragrunt --no-color output -raw note)"
if [[ "$note" != "switched to tofu" ]]; then
  echo "FAIL  note was '${note}'"
  exit 1
fi
pass "apply (${note})"
terragrunt --no-color --non-interactive --working-dir unit run -- destroy -auto-approve -input=false -no-color
rm -rf unit/.terragrunt-cache unit/.terraform
pass "destroy"

echo "PASS  12.1 switch to OpenTofu"
