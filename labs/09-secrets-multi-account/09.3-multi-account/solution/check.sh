#!/usr/bin/env bash
# 09.3 multi-account check. Re-runnable. Config only: this script does not call AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"

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

count_of() {
  local pattern="$1"
  local file="$2"
  grep -E "$pattern" "$file" | grep -Ev '^[[:space:]]*#' | grep -cE "$pattern" || true
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

field() {
  local file="$1"
  local name="$2"
  sed -n "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
}

dev_unit="dev/us-east-1/record"
prod_unit="prod/us-east-1/record"

rm -rf "${dev_unit}/.terragrunt-cache" "${prod_unit}/.terragrunt-cache"

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. dev and prod units are the same file."
if ! cmp -s "${dev_unit}/terragrunt.hcl" "${prod_unit}/terragrunt.hcl"; then
  echo "FAIL  keep the two terragrunt.hcl files identical. Differences belong in account.hcl."
  exit 1
fi
pass "identical units"

echo "== 3. Includes, iam_role, remote state, and the provider stub."
unit_hcl="${dev_unit}/terragrunt.hcl"
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need "$unit_hcl" 'include "root"' 'add include "root"'
need "$unit_hcl" 'include "account"' 'add include "account"'
need "$unit_hcl" 'include "region"' 'add include "region"'
need "$unit_hcl" 'include\.account\.locals\.account_name' 'read account_name from the account include'
need "$unit_hcl" 'include\.account\.locals\.account_id' 'read account_id from the account include'
need "$unit_hcl" 'include\.account\.locals\.role_arn' 'read role_arn from the account include'
need "$unit_hcl" 'include\.account\.locals\.state_bucket' 'read state_bucket from the account include'
need "$unit_hcl" 'include\.region\.locals\.aws_region' 'read aws_region from the region include'
need "$unit_hcl" 'path_relative_to_include\("root"\)' \
  'set unit_path and the state key with path_relative_to_include("root")'
need "$unit_hcl" '^iam_role[[:space:]]*=[[:space:]]*local\.role_arn' \
  'set iam_role = local.role_arn'
need "$unit_hcl" 'backend[[:space:]]*=[[:space:]]*"s3"' 'set remote_state.backend to "s3"'
need "$unit_hcl" 'path[[:space:]]*=[[:space:]]*"backend\.tf"' 'generate backend.tf from remote_state'
need "$unit_hcl" 'bucket[[:space:]]*=[[:space:]]*local\.state_bucket' 'set the state bucket from local.state_bucket'
need "$unit_hcl" 'key[[:space:]]*=[[:space:]]*"\$\{path_relative_to_include\("root"\)\}/terraform\.tfstate"' \
  'set key to ${path_relative_to_include("root")}/terraform.tfstate'
need "$unit_hcl" 'encrypt[[:space:]]*=[[:space:]]*true' 'set encrypt = true'
need "$unit_hcl" 'use_lockfile[[:space:]]*=[[:space:]]*true' 'set use_lockfile = true'
need "$unit_hcl" 'generate[[:space:]]+"provider"' 'add generate "provider"'
need "$unit_hcl" 'path[[:space:]]*=[[:space:]]*"provider\.tf"' 'write the stub to provider.tf'
need "$unit_hcl" 'if_exists[[:space:]]*=[[:space:]]*"overwrite_terragrunt"' \
  'set if_exists to overwrite_terragrunt'
need "$unit_hcl" 'provider[[:space:]]+"aws"' 'the stub should declare provider "aws"'
need "$unit_hcl" 'region[[:space:]]*=[[:space:]]*"\$\{local\.aws_region\}"' \
  'set the provider region from local.aws_region'
need "$unit_hcl" 'dirname\(find_in_parent_folders\("root.hcl"\)\)' \
  'point terraform.source at modules/record next to root.hcl'
need modules/record/versions.tf 'hashicorp/aws' \
  'modules/record/versions.tf should require hashicorp/aws'
forbid "$unit_hcl" '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl. The root include merges it.'
forbid "$unit_hcl" 'assume_role' \
  'leave assume_role out of the provider stub. iam_role already assumed the role.'
forbid "$unit_hcl" 'dynamodb_table' \
  'leave dynamodb_table unset. Locking is use_lockfile.'
forbid "$unit_hcl" 'disable_init[[:space:]]*=[[:space:]]*true' \
  'leave disable_init unset so backend bootstrap can create the bucket'
forbid "$unit_hcl" '"TODO"' 'replace the TODOs'

expose_count="$(count_of 'expose[[:space:]]*=[[:space:]]*true' "$unit_hcl")"
if [[ "$expose_count" -ne 2 ]]; then
  echo "FAIL  expose the account and region includes (found ${expose_count})"
  exit 1
fi
nomerge_count="$(count_of 'merge_strategy[[:space:]]*=[[:space:]]*"no_merge"' "$unit_hcl")"
if [[ "$nomerge_count" -ne 2 ]]; then
  echo "FAIL  set no_merge on the account and region includes (found ${nomerge_count})"
  exit 1
fi
pass "multi-account config"

check_account() {
  local account_dir="$1"
  local account_file="${account_dir}/account.hcl"
  local region_file="${account_dir}/us-east-1/region.hcl"
  local name id role_name bucket region
  name="$(field "$account_file" account_name)"
  id="$(field "$account_file" account_id)"
  role_name="$(field "$account_file" role_name)"
  bucket="$(field "$account_file" state_bucket)"
  region="$(field "$region_file" aws_region)"
  if [[ "$name" != "$account_dir" ]]; then
    echo "FAIL  ${account_dir}: account_name should be ${account_dir}. Found: ${name}"
    exit 1
  fi
  if [[ ! "$id" =~ ^[0-9]{12}$ ]]; then
    echo "FAIL  ${account_dir}: account_id must be 12 digits. Found: ${id}"
    exit 1
  fi
  if [[ "$role_name" != "terragrunt-labs" ]]; then
    echo "FAIL  ${account_dir}: role_name should be terragrunt-labs. Found: ${role_name}"
    exit 1
  fi
  if [[ ! "$bucket" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]]; then
    echo "FAIL  ${account_dir}: state_bucket must be a lowercase S3 name. Found: ${bucket}"
    exit 1
  fi
  if [[ "$region" != "us-east-1" ]]; then
    echo "FAIL  ${account_dir}: aws_region should be us-east-1. Found: ${region}"
    exit 1
  fi
  need "$account_file" 'role_arn[[:space:]]*=[[:space:]]*"arn:aws:iam::\$\{local\.account_id\}:role/\$\{local\.role_name\}"' \
    "${account_dir}: build role_arn from account_id and role_name"
  printf '%s\n' "$id"
  printf '%s\n' "$bucket"
}

echo "== 4. Account stubs differ."
dev_meta="$(check_account dev)"
prod_meta="$(check_account prod)"
dev_id="$(sed -n '1p' <<<"$dev_meta")"
dev_bucket="$(sed -n '2p' <<<"$dev_meta")"
prod_id="$(sed -n '1p' <<<"$prod_meta")"
prod_bucket="$(sed -n '2p' <<<"$prod_meta")"
if [[ "$dev_id" == "$prod_id" ]]; then
  echo "FAIL  dev and prod must use different account ids"
  exit 1
fi
if [[ "$dev_bucket" == "$prod_bucket" ]]; then
  echo "FAIL  dev and prod must use different state buckets"
  exit 1
fi
pass "account stubs"

run_unit() {
  local dir="$1"
  local account_id="$2"
  local bucket="$3"
  local role_arn="arn:aws:iam::${account_id}:role/terragrunt-labs"
  local state_key="${dir}/terraform.tfstate"

  echo "== ${dir}: engine"
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

  echo "== ${dir}: render (no AWS calls)"
  local render_log json_log
  render_log="$(mktemp)"
  json_log="$(mktemp)"
  (
    cd "$dir"
    terragrunt --no-color render
  ) >"$render_log"
  (
    cd "$dir"
    terragrunt --no-color render --format json
  ) >"$json_log"
  python3 - "$json_log" "$account_id" "$bucket" "$role_arn" "$state_key" "$dir" <<'PY'
import json
import sys

path, account_id, bucket, role_arn, state_key, unit = sys.argv[1:]
data = json.load(open(path))
cfg = data["remote_state"]["config"]
errors = []
if data.get("iam_role") != role_arn:
    errors.append("iam_role %s" % data.get("iam_role"))
if cfg.get("bucket") != bucket:
    errors.append("bucket %s" % cfg.get("bucket"))
if cfg.get("key") != state_key:
    errors.append("key %s" % cfg.get("key"))
if cfg.get("region") != "us-east-1":
    errors.append("region %s" % cfg.get("region"))
if cfg.get("encrypt") is not True:
    errors.append("encrypt must be boolean true")
if cfg.get("use_lockfile") is not True:
    errors.append("use_lockfile must be boolean true")
if "role_arn" in cfg:
    errors.append("remote_state role_arn is set")
if "dynamodb_table" in cfg:
    errors.append("dynamodb_table is set")
contents = data["generate"]["provider"]["contents"]
if 'provider "aws"' not in contents:
    errors.append("provider stub")
if 'region = "us-east-1"' not in contents:
    errors.append("provider region")
if "assume_role" in contents:
    errors.append("provider assume_role")
inputs = data["inputs"]
if inputs.get("account_id") != account_id:
    errors.append("input account_id")
if inputs.get("role_arn") != role_arn:
    errors.append("input role_arn")
if inputs.get("unit_path") != unit:
    errors.append("unit_path %s" % inputs.get("unit_path"))
if inputs.get("note") != "multi account":
    errors.append("note")
if errors:
    sys.stderr.write("FAIL  %s: %s\n" % (unit, "; ".join(errors)))
    sys.exit(1)
PY
  pass "${dir} render"
  rm -f "$render_log" "$json_log"
}

run_unit "$dev_unit" "$dev_id" "$dev_bucket"
run_unit "$prod_unit" "$prod_id" "$prod_bucket"

rm -rf "${dev_unit}/.terragrunt-cache" "${prod_unit}/.terragrunt-cache"
echo "PASS  09.3 multi-account"
echo "AWS was not contacted. Follow the README to bootstrap each account when you have credentials."
