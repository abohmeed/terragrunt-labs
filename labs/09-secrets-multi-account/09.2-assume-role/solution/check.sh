#!/usr/bin/env bash
# 09.2 assume role check. Re-runnable. Config only: this script does not call AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"

# Fail fast if a command tries the instance metadata service.
export AWS_EC2_METADATA_DISABLED=true
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE || true

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

rm -rf unit/.terragrunt-cache unit/.terraform

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. iam_role and the generated provider stub."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need root.hcl 'account_id[[:space:]]*=[[:space:]]*"[0-9]{12}"' \
  'set account_id to a 12-digit AWS account id'
need root.hcl 'role_arn[[:space:]]*=[[:space:]]*"arn:aws:iam::\$\{local\.account_id\}:role/terragrunt-labs"' \
  'set role_arn from local.account_id and the role name terragrunt-labs'
need root.hcl '^iam_role[[:space:]]*=[[:space:]]*local\.role_arn' \
  'set iam_role = local.role_arn'
need root.hcl 'generate[[:space:]]+"provider"' \
  'add generate "provider"'
need root.hcl 'path[[:space:]]*=[[:space:]]*"provider\.tf"' \
  'write the stub to provider.tf'
need root.hcl 'if_exists[[:space:]]*=[[:space:]]*"overwrite_terragrunt"' \
  'set generate.if_exists to overwrite_terragrunt'
need root.hcl 'provider[[:space:]]+"aws"' \
  'the stub should declare provider "aws"'
need root.hcl 'region[[:space:]]*=[[:space:]]*"\$\{local\.aws_region\}"' \
  'set the provider region from local.aws_region'
need modules/record/versions.tf 'hashicorp/aws' \
  'modules/record/versions.tf should require hashicorp/aws'
forbid root.hcl 'assume_role' \
  'leave assume_role out of the provider stub. iam_role already assumed the role.'
forbid root.hcl '"TODO"' \
  'replace the TODO'
forbid unit/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid unit/terragrunt.hcl '^iam_role[[:space:]]*=' \
  'leave iam_role in root.hcl'

account_id="$(sed -n 's/^[[:space:]]*account_id[[:space:]]*=[[:space:]]*"\([0-9]\{12\}\)".*/\1/p' root.hcl | head -n 1)"
region="$(sed -n 's/^[[:space:]]*aws_region[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' root.hcl | head -n 1)"
if [[ ! "$account_id" =~ ^[0-9]{12}$ ]]; then
  echo "FAIL  account_id must be 12 digits. Found: ${account_id}"
  exit 1
fi
if [[ ! "$region" =~ ^[a-z]{2}-[a-z0-9-]+-[0-9]+$ ]]; then
  echo "FAIL  set aws_region to an AWS region such as us-east-1. Found: ${region}"
  exit 1
fi
role_arn="arn:aws:iam::${account_id}:role/terragrunt-labs"
pass "assume role config"

echo "== 3. Engine."
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

echo "== 4. Render (no AWS calls)."
render_log="$(mktemp)"
json_log="$(mktemp)"
(
  cd unit
  terragrunt --no-color render
) >"$render_log"
(
  cd unit
  terragrunt --no-color render --format json
) >"$json_log"
need "$render_log" "iam_role[[:space:]]*=[[:space:]]*\"${role_arn}\"" \
  "render iam_role should be ${role_arn}"
need "$render_log" 'provider \\"aws\\"' \
  'render should include provider "aws"'
need "$render_log" "region = \\\\\"${region}\\\\\"" \
  "render should set the provider region to ${region}"
need "$render_log" 'environment[[:space:]]*=[[:space:]]*"dev"' 'render environment'
need "$render_log" 'prefix[[:space:]]*=[[:space:]]*"assume"' 'render prefix'
need "$render_log" 'note[[:space:]]*=[[:space:]]*"assume role"' 'render note'
if grep -q 'assume_role' "$render_log"; then
  echo "FAIL  render still contains assume_role"
  rm -f "$render_log" "$json_log"
  exit 1
fi
if ! grep -Eq "\"iam_role\":[[:space:]]*\"${role_arn}\"" "$json_log"; then
  echo "FAIL  JSON iam_role is not ${role_arn}"
  rm -f "$render_log" "$json_log"
  exit 1
fi
pass "render"
rm -f "$render_log" "$json_log"

rm -rf unit/.terragrunt-cache unit/.terraform
echo "PASS  09.2 assume role"
echo "AWS was not contacted. Follow the README to create the role when you have an account."
