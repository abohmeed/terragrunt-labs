#!/usr/bin/env bash
# 11.2 troubleshooting. Re-runnable. Generated stacks and caches are removed first.
# Run this from start/ after the fix, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +

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

echo "== 2. live/ is a stack. units/record is a unit. They do not share a directory."
if [[ -f live/terragrunt.hcl ]]; then
  echo "FAIL  delete live/terragrunt.hcl. A stack directory cannot also be a unit."
  exit 1
fi
if [[ ! -f live/terragrunt.stack.hcl ]]; then
  echo "FAIL  live/terragrunt.stack.hcl should stay. That file is the stack."
  exit 1
fi
if [[ -f units/record/terragrunt.stack.hcl ]]; then
  echo "FAIL  units/record is a unit. Remove terragrunt.stack.hcl from that directory."
  exit 1
fi
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need units/record/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"traced from render"' \
  'the local note should stay traced from render'
need units/record/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*local\.note' \
  'the input note should read local.note'
need live/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./units/record"' \
  'the stack should source ../units/record'
python3 - << 'PY'
import sys
from pathlib import Path
bad = []
for directory in Path(".").rglob("*"):
    if not directory.is_dir():
        continue
    if any(part.startswith(".") for part in directory.parts):
        continue
    names = {path.name for path in directory.iterdir()}
    if "terragrunt.hcl" in names and "terragrunt.stack.hcl" in names:
        bad.append(str(directory))
if bad:
    sys.stderr.write("FAIL  ambiguous directory: " + ", ".join(bad) + "\n")
    sys.exit(1)
PY
pass "unit and stack are separate"

echo "== 3. The same directory fails discovery when both files are present."
mixed="$(mktemp -d)"
cp live/terragrunt.stack.hcl "$mixed/terragrunt.stack.hcl"
cp units/record/terragrunt.hcl "$mixed/terragrunt.hcl"
mixed_log="$(mktemp)"
set +e
terragrunt --no-color --log-level debug --working-dir "$mixed" stack generate --tf-path terraform >"$mixed_log" 2>&1
mixed_status=$?
set -e
if [[ "$mixed_status" -eq 0 ]]; then
  echo "FAIL  a directory with both files should fail discovery"
  rm -rf "$mixed" "$mixed_log"
  exit 1
fi
if ! grep -Fq "contains both configuration files terragrunt.hcl and terragrunt.stack.hcl" "$mixed_log"; then
  echo "FAIL  expected the ambiguous-directory error"
  cat "$mixed_log"
  rm -rf "$mixed" "$mixed_log"
  exit 1
fi
if ! grep -Fq "A component must be either a unit or a stack, not both." "$mixed_log"; then
  echo "FAIL  expected the unit-or-stack sentence"
  cat "$mixed_log"
  rm -rf "$mixed" "$mixed_log"
  exit 1
fi
pass "ambiguous directory"
rm -rf "$mixed" "$mixed_log"

echo "== 4. scripts/debug.sh renders at debug level."
need scripts/debug.sh '--log-level debug' \
  'debug.sh should pass --log-level debug'
need scripts/debug.sh 'render --format json' \
  'debug.sh should render --format json'
need scripts/debug.sh '--tf-path terraform' \
  'debug.sh should pass --tf-path terraform'
if [[ ! -x scripts/debug.sh ]]; then
  echo "FAIL  scripts/debug.sh should be executable"
  exit 1
fi
debug_log="$(mktemp)"
set +e
./scripts/debug.sh >"$debug_log" 2>&1
debug_status=$?
set -e
if [[ "$debug_status" -ne 0 ]]; then
  echo "FAIL  scripts/debug.sh exited ${debug_status}"
  cat "$debug_log"
  rm -f "$debug_log"
  exit 1
fi
if ! grep -q "DEBUG" "$debug_log"; then
  echo "FAIL  debug log had no DEBUG lines"
  rm -f "$debug_log"
  exit 1
fi
if ! grep -Fq "Running command: terraform -version" "$debug_log"; then
  echo "FAIL  debug log did not show terraform -version. Pass --tf-path terraform."
  rm -f "$debug_log"
  exit 1
fi
if ! grep -Eq '"note"[[:space:]]*:[[:space:]]*"traced from render"' "$debug_log"; then
  echo "FAIL  render JSON did not resolve note to traced from render"
  rm -f "$debug_log"
  exit 1
fi
if grep -Eq '"note"[[:space:]]*:[[:space:]]*"local\.note"' "$debug_log"; then
  echo "FAIL  render JSON still contains the local reference"
  rm -f "$debug_log"
  exit 1
fi
pass "debug render"
rm -f "$debug_log"

echo "== 5. Engine and plan."
engine_log="$(mktemp)"
(
  cd live/.terragrunt-stack/record
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

plan_log="$(mktemp)"
(
  cd live
  terragrunt --no-color --non-interactive stack run --tf-path terraform -- plan -input=false -no-color
) >"$plan_log" 2>&1
if ! grep -q "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log"; then
  echo "FAIL  plan was not 3 to add"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -Fq '"traced from render"' "$plan_log"; then
  echo "FAIL  plan did not show note traced from render"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"

find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
echo "PASS  11.2 troubleshooting"
