#!/usr/bin/env bash
# 11.1 migrate to 1.x. Re-runnable. Generated stacks and caches are removed first.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
rm -rf state

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

need_raw() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

echo "== 1. Terragrunt 1.2.x and formatted HCL."
version_log="$(mktemp)"
terragrunt --version >"$version_log" 2>&1
if ! grep -q "v1\\.2\\." "$version_log"; then
  echo "FAIL  terragrunt was not 1.2.x"
  cat "$version_log"
  rm -f "$version_log"
  exit 1
fi
pass "terragrunt 1.2.x"
rm -f "$version_log"
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. legacy/ keeps the 0.x command and the _envcommon include."
need_raw legacy/commands.sh 'run-all' \
  'legacy/commands.sh should keep the 0.x run-all command'
need_raw legacy/commands.sh '--terragrunt-non-interactive' \
  'legacy/commands.sh should keep --terragrunt-non-interactive'
need_raw legacy/commands.sh '--terragrunt-tfpath' \
  'legacy/commands.sh should keep --terragrunt-tfpath'
need_raw legacy/commands.sh '--terragrunt-exclude-dir' \
  'legacy/commands.sh should keep --terragrunt-exclude-dir'
need_raw legacy/dev/record/terragrunt.hcl '_envcommon/record\.hcl' \
  'legacy dev should include _envcommon/record.hcl'
need_raw legacy/prod/record/terragrunt.hcl '_envcommon/record\.hcl' \
  'legacy prod should include _envcommon/record.hcl'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
pass "legacy snapshot"

echo "== 3. Stacks replace _envcommon. flags.md has the 1.x names."
need live/dev/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./\.\./units/record"' \
  'dev stack source should be ../../units/record'
need live/prod/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./\.\./units/record"' \
  'prod stack source should be ../../units/record'
need live/dev/terragrunt.stack.hcl 'note[[:space:]]*=[[:space:]]*"dev stack"' \
  'dev note should stay dev stack'
need live/prod/terragrunt.stack.hcl 'note[[:space:]]*=[[:space:]]*"prod stack"' \
  'prod note should stay prod stack'
forbid live/dev/terragrunt.stack.hcl '_envcommon' \
  'the dev stack should not include _envcommon'
forbid live/prod/terragrunt.stack.hcl '_envcommon' \
  'the prod stack should not include _envcommon'
forbid live/dev/terragrunt.stack.hcl '"TODO"' \
  'replace the TODO source in live/dev'
forbid live/prod/terragrunt.stack.hcl '"TODO"' \
  'replace the TODO source in live/prod'
need units/record/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*values\.note' \
  'the shared unit should read values.note'
for phrase in \
  'run --all' \
  '--non-interactive' \
  '--tf-path' \
  '--working-dir' \
  '--queue-exclude-dir' \
  '--inputs-debug' \
  '--log-level' \
  'render --format json' \
  'hcl fmt' \
  'TG_NON_INTERACTIVE' \
  'TG_TF_PATH' \
  'TG_INPUTS_DEBUG'
do
  if ! grep -Fq -- "$phrase" flags.md; then
    echo "FAIL  flags.md should contain ${phrase}"
    exit 1
  fi
done
if grep -q 'TODO' flags.md; then
  echo "FAIL  replace the TODOs in flags.md"
  exit 1
fi
pass "stacks and flags.md"

echo "== 4. scripts/queue.sh is the 1.x command."
need scripts/queue.sh 'run --all' \
  'queue.sh should run --all'
need scripts/queue.sh '--non-interactive' \
  'queue.sh should pass --non-interactive'
need scripts/queue.sh '--tf-path terraform' \
  'queue.sh should pass --tf-path terraform'
need scripts/queue.sh '--queue-exclude-dir' \
  'queue.sh should pass --queue-exclude-dir'
need scripts/queue.sh '-- plan' \
  'queue.sh should plan after --'
forbid scripts/queue.sh 'run-all' \
  'queue.sh should not call run-all'
forbid scripts/queue.sh '--terragrunt-' \
  'queue.sh should not use the terragrunt- flag prefix'
if [[ ! -x scripts/queue.sh ]]; then
  echo "FAIL  scripts/queue.sh should be executable"
  exit 1
fi
pass "queue.sh"

echo "== 5. The 1.x queue plans dev and prod and skips legacy."
plan_log="$(mktemp)"
set +e
./scripts/queue.sh >"$plan_log" 2>&1
status=$?
set -e
if [[ "$status" -ne 0 ]]; then
  echo "FAIL  scripts/queue.sh exited ${status}"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
plan_count="$(grep -c "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log" || true)"
if [[ "$plan_count" -ne 2 ]]; then
  echo "FAIL  expected 2 plans that add 3 resources, saw ${plan_count}"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -F 'STDOUT [live/dev/.terragrunt-stack/record]' "$plan_log" | grep -Fq '"dev stack"'; then
  echo "FAIL  dev plan did not show note dev stack"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -F 'STDOUT [live/prod/.terragrunt-stack/record]' "$plan_log" | grep -Fq '"prod stack"'; then
  echo "FAIL  prod plan did not show note prod stack"
  rm -f "$plan_log"
  exit 1
fi
if grep -F 'STDOUT [legacy/' "$plan_log"; then
  echo "FAIL  the queue planned a legacy unit"
  rm -f "$plan_log"
  exit 1
fi
pass "queue plan"
rm -f "$plan_log"

echo "== 6. Engine, then apply and destroy the two stacks."
engine_log="$(mktemp)"
(
  cd live/dev/.terragrunt-stack/record
  terragrunt --no-color run -- version
) >"$engine_log" 2>&1
if ! grep -q "Terraform v1\\.17\\." "$engine_log"; then
  echo "FAIL  engine was not Terraform 1.17.x"
  cat "$engine_log"
  rm -f "$engine_log"
  exit 1
fi
if grep -q "OpenTofu v" "$engine_log"; then
  echo "FAIL  OpenTofu ran. terraform_binary should select Terraform."
  rm -f "$engine_log"
  exit 1
fi
pass "engine"
rm -f "$engine_log"

terragrunt --no-color --non-interactive \
  run --all \
  --tf-path terraform \
  --queue-exclude-dir 'legacy/**' \
  --queue-exclude-dir 'units/**' \
  -- apply -input=false -no-color
dev_note="$(cd live/dev/.terragrunt-stack/record && terragrunt --no-color output -raw note)"
prod_note="$(cd live/prod/.terragrunt-stack/record && terragrunt --no-color output -raw note)"
if [[ "$dev_note" != "dev stack" || "$prod_note" != "prod stack" ]]; then
  echo "FAIL  notes were dev='${dev_note}' prod='${prod_note}'"
  exit 1
fi
pass "apply (${dev_note}, ${prod_note})"

terragrunt --no-color --non-interactive \
  run --all \
  --tf-path terraform \
  --queue-exclude-dir 'legacy/**' \
  --queue-exclude-dir 'units/**' \
  -- destroy -input=false -no-color
find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
rm -rf state
pass "destroy"

echo "PASS  11.1 migrate to 1.x"
