#!/usr/bin/env bash
# 05.2 backend bootstrap check. Re-runnable. Config only: this script does not call AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf dev/.terragrunt-cache prod/.terragrunt-cache

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

echo "== 2. remote_state is S3 with use_lockfile. No DynamoDB table."
need root.hcl 'backend[[:space:]]*=[[:space:]]*"s3"' \
  'set remote_state.backend to "s3"'
need root.hcl 'path[[:space:]]*=[[:space:]]*"backend\.tf"' \
  'generate backend.tf from remote_state'
need root.hcl 'if_exists[[:space:]]*=[[:space:]]*"overwrite_terragrunt"' \
  'set generate.if_exists to overwrite_terragrunt'
need root.hcl 'key[[:space:]]*=[[:space:]]*"\$\{path_relative_to_include\(\)\}/terraform\.tfstate"' \
  'set key to ${path_relative_to_include()}/terraform.tfstate'
need root.hcl 'encrypt[[:space:]]*=[[:space:]]*true' \
  'set encrypt = true'
need root.hcl 'use_lockfile[[:space:]]*=[[:space:]]*true' \
  'set use_lockfile = true'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid root.hcl '^[[:space:]]*dynamodb_table[[:space:]]*=' \
  'leave dynamodb_table unset. Locking is use_lockfile.'
forbid root.hcl 'disable_init[[:space:]]*=[[:space:]]*true' \
  'leave disable_init unset so backend bootstrap can create the bucket'
forbid root.hcl 'bucket[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO bucket name'
forbid root.hcl 'key[[:space:]]*=[[:space:]]*"TODO"' \
  'replace the TODO state key'
forbid dev/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid prod/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'

bucket="$(sed -n 's/^[[:space:]]*bucket[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' root.hcl | head -n 1)"
if [[ ! "$bucket" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]]; then
  echo "FAIL  bucket must be a lowercase S3 name (3-63 characters). Found: ${bucket}"
  exit 1
fi
region="$(sed -n 's/^[[:space:]]*region[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' root.hcl | head -n 1)"
if [[ ! "$region" =~ ^[a-z]{2}-[a-z0-9-]+-[0-9]+$ ]]; then
  echo "FAIL  set region to an AWS region such as us-east-1. Found: ${region}"
  exit 1
fi
pass "remote_state config"

run_unit() {
  local dir="$1"
  local environment="$2"
  local prefix="$3"

  echo "== ${dir}: engine"
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

  echo "== ${dir}: render (no AWS calls)"
  local render_log json_log
  render_log="$(mktemp)"
  json_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color render
  ) | tee "$render_log"
  (
    cd "$dir"
    terragrunt --no-color render --format json
  ) >"$json_log"
  need "$render_log" 'backend[[:space:]]*=[[:space:]]*"s3"' "${dir} render: s3 backend"
  if ! grep -Fq "bucket       = \"${bucket}\"" "$render_log" && ! grep -Fq "bucket = \"${bucket}\"" "$render_log"; then
    echo "FAIL  ${dir}: render bucket is not ${bucket}"
    rm -f "$render_log" "$json_log"
    exit 1
  fi
  need "$render_log" "key[[:space:]]*=[[:space:]]*\"${dir}/terraform.tfstate\"" \
    "${dir} render: key ${dir}/terraform.tfstate"
  need "$render_log" "region[[:space:]]*=[[:space:]]*\"${region}\"" "${dir} render: region"
  need "$render_log" 'encrypt[[:space:]]*=[[:space:]]*true' "${dir} render: encrypt"
  need "$render_log" 'use_lockfile[[:space:]]*=[[:space:]]*true' "${dir} render: use_lockfile"
  need "$render_log" "environment[[:space:]]*=[[:space:]]*\"${environment}\"" "${dir} render: environment"
  need "$render_log" "prefix[[:space:]]*=[[:space:]]*\"${prefix}\"" "${dir} render: prefix"
  need "$render_log" 'note[[:space:]]*=[[:space:]]*"s3 remote state"' "${dir} render: note"
  if ! grep -Eq '"use_lockfile":[[:space:]]*true(,|})' "$json_log"; then
    echo "FAIL  ${dir}: use_lockfile must be the boolean true, not a string"
    rm -f "$render_log" "$json_log"
    exit 1
  fi
  if ! grep -Eq '"encrypt":[[:space:]]*true(,|})' "$json_log"; then
    echo "FAIL  ${dir}: encrypt must be the boolean true"
    rm -f "$render_log" "$json_log"
    exit 1
  fi
  if grep -Fq 'dynamodb_table' "$json_log"; then
    echo "FAIL  ${dir}: render still contains dynamodb_table"
    rm -f "$render_log" "$json_log"
    exit 1
  fi
  pass "${dir} render"
  rm -f "$render_log" "$json_log"

  echo "== ${dir}: inputs match the module variables."
  (
    cd "$dir"
    terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
  )
  pass "${dir} inputs"
}

run_unit dev dev dev-lab
run_unit prod prod prod-lab

rm -rf dev/.terragrunt-cache prod/.terragrunt-cache
echo "PASS  05.2 backend bootstrap"
echo "AWS was not contacted. Follow the README to bootstrap the bucket when you have credentials."
