#!/usr/bin/env bash
# 12.2 OpenTofu specifics. Re-runnable. The cache is removed first.
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

echo "== 2. engine.tofu replaces engine.tf. Encryption stays off."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"tofu"' \
  'root.hcl should set terraform_binary = "tofu"'
if [[ ! -f modules/record/engine.tf || ! -f modules/record/engine.tofu ]]; then
  echo "FAIL  modules/record needs engine.tf and engine.tofu"
  exit 1
fi
need modules/record/engine.tf 'value[[:space:]]*=[[:space:]]*"tf"' \
  'engine.tf should set engine_file to tf'
need modules/record/engine.tofu 'value[[:space:]]*=[[:space:]]*"tofu"' \
  'engine.tofu should set engine_file to tofu'
while IFS= read -r file; do
  if grep -Eq 'encryption[[:space:]]*\{' "$file"; then
    echo "FAIL  ${file} enables encryption. Leave the block out of this lab."
    exit 1
  fi
done < <(find . -type f \( -name '*.tf' -o -name '*.tofu' -o -name '*.hcl' \))
pass "engine files"

echo "== 3. differences.md records the OpenTofu behavior."
for phrase in \
  'engine.tofu' \
  'ignores `engine.tf`' \
  'Terraform ignores' \
  'TF_ENCRYPTION' \
  'does not enable encryption' \
  'registry.opentofu.org' \
  '1.13' \
  '1.17' \
  'TG_TF_PATH' \
  'not byte-for-byte identical'
do
  if ! grep -Fq -- "$phrase" differences.md; then
    echo "FAIL  differences.md should contain ${phrase}"
    exit 1
  fi
done
if grep -q 'TODO' differences.md; then
  echo "FAIL  replace the TODOs in differences.md"
  exit 1
fi
pass "differences.md"

echo "== 4. Apply with OpenTofu. engine_file is tofu. Then destroy."
apply_log="$(mktemp)"
terragrunt --no-color --non-interactive --working-dir unit run -- apply -auto-approve -input=false -no-color >"$apply_log" 2>&1
if ! grep -Fq 'engine_file = "tofu"' "$apply_log"; then
  echo "FAIL  the plan did not set engine_file to tofu"
  cat "$apply_log"
  rm -f "$apply_log"
  exit 1
fi
if grep -Fq 'engine_file = "tf"' "$apply_log"; then
  echo "FAIL  OpenTofu also loaded engine.tf"
  rm -f "$apply_log"
  exit 1
fi
pass "plan selected engine.tofu"
rm -f "$apply_log"
engine_file="$(cd unit && terragrunt --no-color output -raw engine_file)"
note="$(cd unit && terragrunt --no-color output -raw note)"
if [[ "$engine_file" != "tofu" ]]; then
  echo "FAIL  engine_file was '${engine_file}'"
  exit 1
fi
if [[ "$note" != "tofu specifics" ]]; then
  echo "FAIL  note was '${note}'"
  exit 1
fi
version_log="$(mktemp)"
(
  cd unit
  terragrunt --no-color run -- version
) >"$version_log" 2>&1
if ! grep -q "OpenTofu v1\\.13\\." "$version_log"; then
  echo "FAIL  the unit did not run OpenTofu 1.13.x"
  cat "$version_log"
  rm -f "$version_log"
  exit 1
fi
pass "apply (${engine_file}, ${note})"
rm -f "$version_log"
terragrunt --no-color --non-interactive --working-dir unit run -- destroy -auto-approve -input=false -no-color
rm -rf unit/.terragrunt-cache unit/.terraform
pass "destroy"

echo "PASS  12.2 OpenTofu specifics"
