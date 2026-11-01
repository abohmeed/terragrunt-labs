#!/usr/bin/env bash
# 01.1 why Terragrunt. Reads local files only. Nothing is installed or applied.
# The same script lives in start/ and solution/.
set -euo pipefail

cd "$(dirname "$0")"

pass() {
  echo "PASS  $*"
}

fail() {
  echo "FAIL  $*"
  exit 1
}

quoted() {
  local file="$1"
  local pattern="$2"
  local line
  line="$(grep -E -- "$pattern" "$file")"
  printf '%s\n' "$line" | sed -E 's/.*"([^"]+)".*/\1/'
}

check_readme() {
  local readme="../README.md"
  [[ -f "$readme" ]] || fail "lecture README is missing"
  grep -Fq '## Goal' "$readme" || fail "README should have a Goal section"
  grep -Fq '## Steps' "$readme" || fail "README should have a Steps section"
  pass "README"
}

check_copies() {
  local env file
  for env in dev staging prod; do
    for file in main.tf backend.tf provider.tf terraform.tfvars; do
      [[ -f "${env}/${file}" ]] || fail "missing ${env}/${file}"
    done
    if grep -REq 'hashicorp/aws|provider[[:space:]]+"aws"|backend[[:space:]]+"s3"' "${env}"; then
      fail "${env} should stay offline. No AWS provider and no S3 backend."
    fi
    pass "${env} copy"
  done

  cmp -s dev/main.tf staging/main.tf || fail "staging/main.tf should be a copy of dev/main.tf"
  cmp -s dev/main.tf prod/main.tf || fail "prod/main.tf should be a copy of dev/main.tf"
  grep -Fq 'random_pet' dev/main.tf || fail "main.tf should be the small copied root"
  pass "main.tf is duplicated"

  local -a paths=()
  local path_value
  for env in dev staging prod; do
    if grep -Eq 'var\.|local\.' "${env}/backend.tf"; then
      fail "${env}/backend.tf should hard-code the path. The backend block cannot use variables."
    fi
    path_value="$(quoted "${env}/backend.tf" '^[[:space:]]*path[[:space:]]*=')"
    [[ -n "$path_value" ]] || fail "${env}/backend.tf needs a hard-coded path"
    [[ "$path_value" == *"${env}"* ]] || fail "${env}/backend.tf path should name ${env}. Got ${path_value}"
    paths+=("$path_value")
  done
  if [[ "${paths[0]}" == "${paths[1]}" || "${paths[0]}" == "${paths[2]}" || "${paths[1]}" == "${paths[2]}" ]]; then
    fail "the three backend paths should differ. Got: ${paths[*]}"
  fi
  pass "backend paths are hard-coded and different"

  local -a reqs=() vers=()
  local req ver
  for env in dev staging prod; do
    req="$(grep -E '^[[:space:]]*required_version[[:space:]]*=' "${env}/provider.tf")"
    ver="$(grep -E '^[[:space:]]*version[[:space:]]*=' "${env}/provider.tf")"
    [[ -n "$req" && -n "$ver" ]] || fail "${env}/provider.tf needs required_version and a provider version"
    reqs+=("$req")
    vers+=("$ver")
  done
  if [[ "${reqs[0]}" == "${reqs[1]}" || "${reqs[0]}" == "${reqs[2]}" || "${reqs[1]}" == "${reqs[2]}" ]]; then
    fail "required_version should drift. dev was updated and the other copies were not."
  fi
  if [[ "${vers[0]}" == "${vers[1]}" || "${vers[0]}" == "${vers[2]}" || "${vers[1]}" == "${vers[2]}" ]]; then
    fail "provider version should drift across the copies"
  fi
  grep -Eq '1\.17' dev/provider.tf || fail "dev/provider.tf should ask for Terraform 1.17"
  grep -Eq '3\.6' dev/provider.tf || fail "dev/provider.tf should ask for random 3.6"
  pass "provider versions drifted"

  local -a prefixes=()
  local prefix
  for env in dev staging prod; do
    prefix="$(quoted "${env}/terraform.tfvars" '^prefix[[:space:]]*=')"
    [[ "$prefix" == "$env" ]] || fail "${env}/terraform.tfvars prefix should be ${env}"
    prefixes+=("$prefix")
  done
  if [[ "${prefixes[0]}" == "${prefixes[1]}" || "${prefixes[1]}" == "${prefixes[2]}" ]]; then
    fail "terraform.tfvars prefix should differ per copy"
  fi
  pass "tfvars differ"

  if find . -name 'terragrunt.hcl' -print | grep -q .; then
    fail "the copied roots are plain Terraform. The unit sketch belongs in solution/"
  fi
  pass "copies are plain Terraform"
}

check_solution() {
  [[ -f unit/terragrunt.hcl ]] || fail "missing unit/terragrunt.hcl"
  [[ -f modules/record/main.tf ]] || fail "missing modules/record/main.tf"
  [[ -f modules/record/variables.tf ]] || fail "missing modules/record/variables.tf"
  [[ -f modules/record/versions.tf ]] || fail "missing modules/record/versions.tf"
  [[ -f NOTES.md ]] || fail "missing NOTES.md"

  grep -Eq 'terraform_binary[[:space:]]*=[[:space:]]*"terraform"' unit/terragrunt.hcl \
    || fail 'unit should set terraform_binary = "terraform"'
  grep -Eq 'source[[:space:]]*=[[:space:]]*"\.\./modules/record"' unit/terragrunt.hcl \
    || fail "unit should point source at ../modules/record"
  grep -Eq '^[[:space:]]*prefix[[:space:]]*=' unit/terragrunt.hcl \
    || fail "unit should set an input prefix"
  if grep -REq 'hashicorp/aws|provider[[:space:]]+"aws"|backend[[:space:]]+"s3"' unit modules; then
    fail "the unit sketch should stay offline"
  fi
  pass "unit sketch"

  local phrase
  for phrase in "unit" "stack" "terragrunt.stack.hcl" "backend" "drift"; do
    grep -Fq -- "$phrase" NOTES.md || fail "NOTES.md should mention ${phrase}"
  done
  pass "NOTES.md"
}

check_readme

case "$(basename "$(pwd)")" in
  start)
    check_copies
    echo "PASS  01.1 why Terragrunt"
    ;;
  solution)
    check_solution
    echo "PASS  01.1 solution"
    ;;
  *)
    fail "run this script from start/ or solution/"
    ;;
esac
