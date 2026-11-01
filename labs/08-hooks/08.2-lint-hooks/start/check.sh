#!/usr/bin/env bash
# 08.2 lint hooks check. Re-runnable. Caches are removed first.
# Run this from start/ after the TODOs, or from solution/.
# tflint is not in the repo. This script installs the .mise.toml pin when
# the binary is missing, and skips the live plan only if that install fails.
set -euo pipefail

cd "$(dirname "$0")"

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

assert_tg() {
  local version_log
  version_log="$(mktemp)"
  terragrunt --version >"$version_log" 2>&1
  if ! grep -q "v1\.2\." "$version_log"; then
    echo "FAIL  terragrunt was not 1.2.x"
    cat "$version_log"
    rm -f "$version_log"
    exit 1
  fi
  pass "terragrunt 1.2.x"
  rm -f "$version_log"
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

clean_runtime() {
  find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
  find . \( -name '*.tfstate' -o -name '*.tfstate.*' \) -delete
}

plan_count() {
  local file="$1"
  grep -c "Plan: 3 to add, 0 to change, 0 to destroy." "$file" || true
}

ensure_tflint() {
  if command -v tflint >/dev/null 2>&1; then
    return 0
  fi
  local root bin os arch url tmp
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" ]] && command -v mise >/dev/null 2>&1; then
    (cd "$root" && mise install tflint)
    bin="$(cd "$root" && mise which tflint)"
    export PATH="$(dirname "$bin"):${PATH}"
  fi
  if command -v tflint >/dev/null 2>&1; then
    return 0
  fi
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) return 1 ;;
  esac
  case "$os" in
    linux | darwin) ;;
    *) return 1 ;;
  esac
  tmp="$(mktemp -d)"
  url="https://github.com/terraform-linters/tflint/releases/download/v0.65.0/tflint_${os}_${arch}.zip"
  if ! curl -fsSL -o "${tmp}/tflint.zip" "$url"; then
    return 1
  fi
  unzip -q "${tmp}/tflint.zip" -d "$tmp"
  export PATH="${tmp}:${PATH}"
  command -v tflint >/dev/null 2>&1
}

clean_runtime

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. The mise pin and the three before hooks."
repo_root="$(git rev-parse --show-toplevel)"
need "${repo_root}/.mise.toml" '^tflint[[:space:]]*=[[:space:]]*"0\.65\.0"' \
  '.mise.toml should pin tflint = "0.65.0"'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid unit/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need unit/terragrunt.hcl 'before_hook[[:space:]]+"tflint"' \
  'add before_hook "tflint"'
need unit/terragrunt.hcl 'execute[[:space:]]*=[[:space:]]*\[[[:space:]]*"tflint"' \
  'the tflint hook should execute the tflint binary, not an absolute path'
need unit/terragrunt.hcl 'minimum-failure-severity=error' \
  'tflint should fail the hook on errors and let warnings pass'
need unit/terragrunt.hcl 'before_hook[[:space:]]+"fmt"' \
  'add before_hook "fmt"'
need unit/terragrunt.hcl '"terraform", "fmt", "-check", "-diff"' \
  'the fmt hook should run terraform fmt -check -diff'
need unit/terragrunt.hcl 'before_hook[[:space:]]+"checkov"' \
  'add before_hook "checkov"'
need unit/terragrunt.hcl 'hooks/checkov' \
  'the checkov hook should call hooks/checkov'
need unit/terragrunt.hcl '"--framework", "terraform"' \
  'the checkov hook should pass --framework terraform'
need unit/terragrunt.hcl '"--quiet"' \
  'the checkov hook should pass --quiet'
need unit/terragrunt.hcl '"--compact"' \
  'the checkov hook should pass --compact'
need .tflint.hcl 'terraform_unused_declarations' \
  '.tflint.hcl should enable terraform_unused_declarations'
need .tflint.hcl 'terraform_standard_module_structure' \
  '.tflint.hcl should mention terraform_standard_module_structure'
need .tflint.hcl 'enabled[[:space:]]*=[[:space:]]*false' \
  'leave terraform_standard_module_structure disabled'
forbid .tflint.hcl '^plugin[[:space:]]+"' \
  'do not add a plugin block. tflint 0.65.0 already ships ruleset.terraform'
[[ -x hooks/checkov ]]
pass "lint hook config"

echo "== 3. The checkov script rejects allow_all and accepts a clean module."
bad="$(mktemp -d)"
printf 'resource "null_resource" "open" {\n  triggers = {\n    allow_all = "true"\n  }\n}\n' >"${bad}/main.tf"
bad_log="$(mktemp)"
set +e
LAB_CHECKOV_STUB=1 ./hooks/checkov -d "$bad" --framework terraform --quiet --compact >"$bad_log" 2>&1
bad_status=$?
set -e
if [[ "$bad_status" -eq 0 ]]; then
  echo "FAIL  hooks/checkov accepted allow_all"
  cat "$bad_log"
  rm -rf "$bad"
  rm -f "$bad_log"
  exit 1
fi
if ! grep -q 'allow_all' "$bad_log"; then
  echo "FAIL  hooks/checkov did not report allow_all"
  cat "$bad_log"
  rm -rf "$bad"
  rm -f "$bad_log"
  exit 1
fi
pass "checkov stub rejects allow_all"
rm -rf "$bad"
rm -f "$bad_log"

clean_log="$(mktemp)"
LAB_CHECKOV_STUB=1 ./hooks/checkov -d modules/record --framework terraform --quiet --compact >"$clean_log" 2>&1
if ! grep -q 'checkov stub: no findings' "$clean_log"; then
  echo "FAIL  hooks/checkov rejected the record module"
  cat "$clean_log"
  rm -f "$clean_log"
  exit 1
fi
pass "checkov stub accepts the module"
rm -f "$clean_log"

echo "== 4. Plan runs tflint, fmt, and the checkov hook before Terraform."
if ! ensure_tflint; then
  echo "SKIP  tflint 0.65.0 is not on PATH and could not be installed. Hook text was checked."
  clean_runtime
  echo "PASS  08.2 lint hooks"
  exit 0
fi
version_log="$(mktemp)"
tflint --version >"$version_log" 2>&1
if ! grep -q '0\.65\.' "$version_log"; then
  echo "FAIL  tflint was not 0.65.x. .mise.toml pins 0.65.0."
  cat "$version_log"
  rm -f "$version_log"
  exit 1
fi
pass "tflint 0.65.x"
rm -f "$version_log"

assert_engine unit
plan_log="$(mktemp)"
(
  cd unit
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if [[ "$(plan_count "$plan_log")" -lt 1 ]]; then
  echo "FAIL  plan was not 3 to add"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'Tflint has run successfully. No issues found.' "$plan_log"; then
  echo "FAIL  tflint did not report a clean module"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'Executing hook: fmt' "$plan_log"; then
  echo "FAIL  the fmt hook did not run"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'Executing hook: checkov' "$plan_log"; then
  echo "FAIL  the checkov hook did not run"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'lint hooks' "$plan_log"; then
  echo "FAIL  plan did not keep note \"lint hooks\""
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "linted plan"
rm -f "$plan_log"

clean_runtime
echo "PASS  08.2 lint hooks"
