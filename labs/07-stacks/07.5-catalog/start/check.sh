#!/usr/bin/env bash
# 07.5 catalog check. Re-runnable. Generated stacks and caches are removed first.
# Run this from start/ after the TODO, or from solution/.
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


clean_runtime

echo "== 1. Terragrunt 1.2.x and formatted HCL."
assert_tg
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. The catalog block points at the local catalog. The stack uses //."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need root.hcl 'catalog[[:space:]]*\{' \
  'add a catalog block in root.hcl'
need root.hcl 'urls[[:space:]]*=' \
  'set catalog urls'
need root.hcl '"\./catalog"' \
  'set the catalog url to "./catalog"'
forbid root.hcl 'github\.com' \
  'keep this lecture on the local catalog'
need live/terragrunt.stack.hcl 'source[[:space:]]*=[[:space:]]*"\.\./catalog//units/record"' \
  'set source = "../catalog//units/record"'
need live/terragrunt.stack.hcl 'path[[:space:]]*=[[:space:]]*"record"' \
  'keep path = "record"'
forbid live/terragrunt.stack.hcl '"TODO"' \
  'replace the TODO source'
[[ -f catalog/modules/record/main.tf ]]
[[ -f catalog/units/record/terragrunt.hcl ]]
[[ -f catalog/stacks/platform/terragrunt.stack.hcl ]]
pass "catalog block and stack source"

echo "== 3. terragrunt catalog --format=jsonl lists a module, a unit, and a stack."
tmp="$(mktemp -d)"
python3 - "$tmp/lab" << 'PY'
import shutil, sys
from pathlib import Path
dest = Path(sys.argv[1])
shutil.copytree(Path("."), dest, ignore=shutil.ignore_patterns(".terragrunt-cache", ".terraform", ".terragrunt-stack"))
PY
git -C "$tmp/lab/catalog" init -q
catalog_log="$(mktemp)"
catalog_err="$(mktemp)"
(
  cd "$tmp/lab"
  terragrunt --no-color catalog --format=jsonl --root-file-name root.hcl
) >"$catalog_log" 2>"$catalog_err"
python3 - "$catalog_log" << 'PY'
import json, sys
rows = []
for line in open(sys.argv[1]):
    line = line.strip()
    if not line:
        continue
    rows.append(json.loads(line))
found = {(row.get("kind"), row.get("dir"), row.get("title")) for row in rows}
need = {
    ("module", "modules/record", "Record"),
    ("unit", "units/record", "Record unit"),
    ("stack", "stacks/platform", "Platform"),
}
missing = need - found
if missing:
    print("FAIL  catalog entries missing: " + ", ".join(sorted(map(str, missing))))
    print("got: " + ", ".join(sorted(map(str, found))))
    sys.exit(1)
for row in rows:
    source = row.get("component_source") or ""
    if "//" not in source:
        print(f"FAIL  component_source has no // : {source}")
        sys.exit(1)
print("PASS  catalog jsonl")
PY
rm -rf "$tmp" "$catalog_log" "$catalog_err"
pass "catalog"

echo "== 4. Generate the catalog unit and plan it."
(
  cd live
  terragrunt --no-color stack generate
)
[[ -f live/.terragrunt-stack/record/terragrunt.hcl ]]
plan_log="$(mktemp)"
(
  cd live
  terragrunt --no-color --non-interactive stack run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if [[ "$(plan_count "$plan_log")" -ne 1 ]]; then
  echo "FAIL  expected one plan of 3 adds, got $(plan_count "$plan_log")"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'catalog unit' "$plan_log"; then
  echo "FAIL  plan did not use the catalog unit note"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "catalog unit plan"
rm -f "$plan_log"
assert_engine live/.terragrunt-stack/record

clean_runtime
echo "PASS  07.5 catalog"
