#!/usr/bin/env bash
# 08.3 errors block check. Re-runnable. Caches, the attempt counter, and
# error signals are removed first.
# Run this from start/ after the TODOs, or from solution/.
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
  find . \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name attempt.count -o -name error-signals.json \) -delete
}

clean_runtime

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. retry and ignore are separate units. terraform_binary stays in root.hcl."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
forbid retry/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid ignore/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need retry/terragrunt.hcl 'retry[[:space:]]+"transient_network"' \
  'add retry "transient_network" on the flaky unit'
need retry/terragrunt.hcl 'Error: transient' \
  'retryable_errors should match Error: transient'
need retry/terragrunt.hcl 'max_attempts[[:space:]]*=[[:space:]]*3' \
  'set max_attempts = 3'
need retry/terragrunt.hcl 'sleep_interval_sec[[:space:]]*=[[:space:]]*1' \
  'set sleep_interval_sec = 1'
need retry/terragrunt.hcl 'get_terragrunt_dir\(\)}/attempt\.count' \
  'keep the attempt counter next to the unit, outside .terragrunt-cache'
forbid retry/terragrunt.hcl 'ignore[[:space:]]+"' \
  'keep the ignore block on the drift unit'
need ignore/terragrunt.hcl 'ignore[[:space:]]+"known_drift"' \
  'add ignore "known_drift" on the drift unit'
need ignore/terragrunt.hcl 'Error: safe-to-ignore' \
  'ignorable_errors should match Error: safe-to-ignore'
need ignore/terragrunt.hcl 'Error: do not ignore' \
  'keep the negative pattern that excludes Error: do not ignore'
need ignore/terragrunt.hcl 'Ignoring safe-to-ignore drift' \
  'set message = "Ignoring safe-to-ignore drift"'
need ignore/terragrunt.hcl 'safe_to_revert[[:space:]]*=[[:space:]]*true' \
  'set signals.safe_to_revert = true'
forbid ignore/terragrunt.hcl 'retry[[:space:]]+"' \
  'keep the retry block on the flaky unit'
need modules/flaky/main.tf 'Error: transient' \
  'leave the flaky provisioner printing Error: transient'
need modules/drift/main.tf 'Error: safe-to-ignore' \
  'leave the drift provisioner failing with Error: safe-to-ignore'
pass "errors blocks"

echo "== 3. Apply retries the transient failure, then succeeds."
assert_engine retry
retry_log="$(mktemp)"
(
  cd retry
  terragrunt --no-color --non-interactive run -- apply -input=false -auto-approve -no-color
) >"$retry_log" 2>&1
if ! grep -q 'Encountered retryable error: transient_network' "$retry_log"; then
  echo "FAIL  apply did not retry transient_network"
  cat "$retry_log"
  rm -f "$retry_log"
  exit 1
fi
if ! grep -q 'Attempt 1 of 3' "$retry_log"; then
  echo "FAIL  apply did not record attempt 1 of 3"
  cat "$retry_log"
  rm -f "$retry_log"
  exit 1
fi
if ! grep -q 'Waiting 1 second' "$retry_log"; then
  echo "FAIL  the retry did not wait 1 second"
  cat "$retry_log"
  rm -f "$retry_log"
  exit 1
fi
if ! grep -q 'Apply complete!' "$retry_log"; then
  echo "FAIL  the retried apply did not complete"
  cat "$retry_log"
  rm -f "$retry_log"
  exit 1
fi
if [[ ! -f retry/attempt.count ]] || [[ "$(tr -d '[:space:]' <retry/attempt.count)" != "2" ]]; then
  echo "FAIL  attempt.count was not 2. The first call should fail and the second should pass."
  cat retry/attempt.count 2>/dev/null || true
  cat "$retry_log"
  rm -f "$retry_log"
  exit 1
fi
pass "retry apply"
rm -f "$retry_log"

echo "== 4. Apply ignores the known drift and writes error signals."
assert_engine ignore
ignore_log="$(mktemp)"
(
  cd ignore
  terragrunt --no-color --non-interactive run -- apply -input=false -auto-approve -no-color
) >"$ignore_log" 2>&1
if ! grep -q 'Ignoring safe-to-ignore drift' "$ignore_log"; then
  echo "FAIL  apply did not ignore the drift error"
  cat "$ignore_log"
  rm -f "$ignore_log"
  exit 1
fi
if [[ ! -f ignore/error-signals.json ]]; then
  echo "FAIL  ignore/error-signals.json was not written"
  cat "$ignore_log"
  rm -f "$ignore_log"
  exit 1
fi
if ! grep -q '"safe_to_revert": true' ignore/error-signals.json; then
  echo "FAIL  error-signals.json did not record safe_to_revert true"
  cat ignore/error-signals.json
  rm -f "$ignore_log"
  exit 1
fi
pass "ignore apply"
rm -f "$ignore_log"

clean_runtime
echo "PASS  08.3 errors block"
