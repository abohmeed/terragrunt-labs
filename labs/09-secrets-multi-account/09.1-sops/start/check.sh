#!/usr/bin/env bash
# 09.1 SOPS check. Re-runnable. The cache and the temporary age key are removed.
# Run this from start/ after the TODOs, or from solution/.
# The script generates an age key outside the repo, encrypts secrets.example.yaml,
# and deletes the key. It does not keep a private key or a real secret.
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

keydir=""
enc_backup=""
enc_created=0

cleanup() {
  local status=$?
  if [[ -n "$keydir" ]]; then
    rm -rf "$keydir"
  fi
  if [[ "$enc_created" -eq 1 ]]; then
    if [[ -n "$enc_backup" ]]; then
      mv "$enc_backup" secrets.enc.yaml
    else
      rm -f secrets.enc.yaml
    fi
  fi
  rm -rf unit/.terragrunt-cache unit/.terraform
  if [[ -d unit ]]; then
    find unit \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name '.terraform.tfstate.lock.info' \) -delete
  fi
  exit "$status"
}
trap cleanup EXIT

download() {
  local url="$1"
  local dest="$2"
  curl -fsSL -o "$dest" "$url"
}

ensure_sops() {
  if command -v sops >/dev/null 2>&1; then
    return 0
  fi
  local root bin os arch url tmp
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" ]] && command -v mise >/dev/null 2>&1; then
    (cd "$root" && mise install sops)
    bin="$(cd "$root" && mise which sops)"
    export PATH="$(dirname "$bin"):${PATH}"
  fi
  if command -v sops >/dev/null 2>&1; then
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
  url="https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.${os}.${arch}"
  if ! download "$url" "${tmp}/sops"; then
    return 1
  fi
  chmod +x "${tmp}/sops"
  export PATH="${tmp}:${PATH}"
  command -v sops >/dev/null 2>&1
}

ensure_age() {
  if command -v age >/dev/null 2>&1 && command -v age-keygen >/dev/null 2>&1; then
    return 0
  fi
  local root bin os arch url tmp
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" ]] && command -v mise >/dev/null 2>&1; then
    (cd "$root" && mise install age)
    bin="$(cd "$root" && mise which age)"
    export PATH="$(dirname "$bin"):${PATH}"
  fi
  if command -v age >/dev/null 2>&1 && command -v age-keygen >/dev/null 2>&1; then
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
  url="https://github.com/FiloSottile/age/releases/download/v1.3.2/age-v1.3.2-${os}-${arch}.tar.gz"
  if ! download "$url" "${tmp}/age.tar.gz"; then
    return 1
  fi
  tar -xzf "${tmp}/age.tar.gz" -C "$tmp"
  export PATH="${tmp}/age:${PATH}"
  command -v age >/dev/null 2>&1 && command -v age-keygen >/dev/null 2>&1
}

rm -rf unit/.terragrunt-cache unit/.terraform

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Pins, decrypt call, and no private key in the tree."
repo_root="$(git rev-parse --show-toplevel)"
need "${repo_root}/.mise.toml" '^sops[[:space:]]*=[[:space:]]*"3\.13\.3"' \
  '.mise.toml should pin sops = "3.13.3"'
need "${repo_root}/.mise.toml" '^age[[:space:]]*=[[:space:]]*"1\.3\.2"' \
  '.mise.toml should pin age = "1.3.2"'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid unit/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need unit/terragrunt.hcl 'get_env\("SOPS_AGE_KEY_FILE"\)' \
  'read the age key path with get_env("SOPS_AGE_KEY_FILE") and no default'
need unit/terragrunt.hcl 'sops_decrypt_file\(' \
  'decrypt with sops_decrypt_file'
need unit/terragrunt.hcl 'secrets\.enc\.yaml' \
  'point sops_decrypt_file at secrets.enc.yaml'
need unit/terragrunt.hcl 'yamldecode\(' \
  'yamldecode the decrypted file'
need unit/terragrunt.hcl 'local\.secrets\.db_password' \
  'pass local.secrets.db_password into inputs'
need unit/terragrunt.hcl 'local\.secrets\.note' \
  'pass local.secrets.note into inputs'
need unit/terragrunt.hcl 'length\(trimspace\(local\.age_key_file\)\)' \
  'set age_key_configured from the key path'
forbid unit/terragrunt.hcl 'secrets\.example\.yaml' \
  'decrypt secrets.enc.yaml. Leave secrets.example.yaml as the plaintext shape.'
forbid unit/terragrunt.hcl 'db_password[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO db_password'
forbid unit/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO note'
if grep -R -n -E --exclude-dir=.terragrunt-cache --exclude-dir=.terraform \
  --exclude=check.sh --exclude='*.md' \
  'AGE-SECRET-KEY-1[A-Z0-9]{20,}' .; then
  echo "FAIL  an age private key is in the lab tree. Keep it outside the repo."
  exit 1
fi
pass "sops config"

echo "== 3. sops 3.13.3 and age 1.3.2."
if ! ensure_sops || ! ensure_age; then
  echo "FAIL  sops 3.13.3 and age 1.3.2 are not on PATH and could not be installed."
  exit 1
fi
export SOPS_DISABLE_VERSION_CHECK=1
tool_log="$(mktemp)"
sops --version >"$tool_log" 2>&1
age --version >>"$tool_log" 2>&1
age-keygen --version >>"$tool_log" 2>&1
if ! grep -q "3\.13\.3" "$tool_log"; then
  echo "FAIL  sops was not 3.13.3. .mise.toml pins 3.13.3."
  cat "$tool_log"
  rm -f "$tool_log"
  exit 1
fi
if ! grep -q "1\.3\.2" "$tool_log"; then
  echo "FAIL  age was not 1.3.2. .mise.toml pins 1.3.2."
  cat "$tool_log"
  rm -f "$tool_log"
  exit 1
fi
pass "sops and age"
rm -f "$tool_log"

echo "== 4. Encrypt the example with a temporary age key."
unset SOPS_AGE_KEY
unset SOPS_AGE_KEY_CMD
keydir="$(mktemp -d)"
age-keygen -o "${keydir}/keys.txt" >/dev/null 2>&1
pub="$(age-keygen -y "${keydir}/keys.txt")"
if [[ -f secrets.enc.yaml ]]; then
  enc_backup="$(mktemp)"
  cp secrets.enc.yaml "$enc_backup"
fi
sops --encrypt --age "$pub" --filename-override secrets.enc.yaml secrets.example.yaml >secrets.enc.yaml
enc_created=1
export SOPS_AGE_KEY_FILE="${keydir}/keys.txt"
if grep -q "AGE-SECRET-KEY-" secrets.enc.yaml; then
  echo "FAIL  secrets.enc.yaml contains an age private key"
  exit 1
fi
pass "encrypted with a temporary key"

echo "== 5. Engine."
version_log="$(mktemp)"
(
  cd unit
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
pass "engine is Terraform 1.17.x"
rm -f "$version_log"

echo "== 6. Render decrypts the lab fixture."
render_log="$(mktemp)"
(
  cd unit
  terragrunt --no-color render
) >"$render_log"
need "$render_log" 'db_password[[:space:]]*=[[:space:]]*"lab-db-password"' \
  'render should decrypt db_password to the lab fixture'
need "$render_log" 'note[[:space:]]*=[[:space:]]*"sops age"' \
  'render should decrypt note to "sops age"'
need "$render_log" 'age_key_configured[[:space:]]*=[[:space:]]*true' \
  'render should set age_key_configured = true'
if grep -q "AGE-SECRET-KEY-" "$render_log"; then
  echo "FAIL  render printed an age private key"
  rm -f "$render_log"
  exit 1
fi
pass "render"
rm -f "$render_log"

echo "== 7. Inputs match the module variables."
(
  cd unit
  terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
)
pass "inputs"

echo "== 8. Apply, output, destroy."
(
  cd unit
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
password="$(
  cd unit
  terragrunt --no-color --non-interactive run -- output -raw db_password
)"
note="$(
  cd unit
  terragrunt --no-color --non-interactive run -- output -raw note
)"
configured="$(
  cd unit
  terragrunt --no-color --non-interactive run -- output -raw age_key_configured
)"
if [[ "$password" != "lab-db-password" ]]; then
  echo "FAIL  db_password output was not the lab fixture"
  exit 1
fi
if [[ "$note" != "sops age" ]]; then
  echo "FAIL  note output was not \"sops age\""
  exit 1
fi
if [[ "$configured" != "true" ]]; then
  echo "FAIL  age_key_configured output was not true"
  exit 1
fi
pass "apply"
(
  cd unit
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "destroy"

echo "PASS  09.1 sops"
