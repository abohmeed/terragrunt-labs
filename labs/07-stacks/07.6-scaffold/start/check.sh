#!/usr/bin/env bash
# 07.6 scaffold check. Re-runnable. Generated stacks and caches are removed first.
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

echo "== 2. Catalog lists the module, the unit, and the stack."
need root.hcl 'catalog[[:space:]]*\{' \
  'root.hcl should keep the catalog block'
need root.hcl '"\./catalog"' \
  'root.hcl should point the catalog at ./catalog'
forbid root.hcl 'github\.com' \
  'keep this lecture on the local catalog'
tmp="$(mktemp -d)"
python3 - "$tmp/lab" << 'PY'
import shutil, sys
from pathlib import Path
dest = Path(sys.argv[1])
shutil.copytree(Path("."), dest, ignore=shutil.ignore_patterns(".terragrunt-cache", ".terraform", ".terragrunt-stack", "live", "stamped"))
PY
git -C "$tmp/lab/catalog" init -q
catalog_log="$(mktemp)"
(
  cd "$tmp/lab"
  terragrunt --no-color catalog --format=jsonl --root-file-name root.hcl
) >"$catalog_log"
python3 - "$catalog_log" << 'PY'
import json, sys
found = set()
for line in open(sys.argv[1]):
    line = line.strip()
    if not line:
        continue
    row = json.loads(line)
    found.add((row.get("kind"), row.get("dir")))
need = {("module", "modules/record"), ("unit", "units/record"), ("stack", "stacks/platform")}
missing = need - found
if missing:
    print("FAIL  catalog entries missing: " + ", ".join(sorted(map(str, missing))))
    sys.exit(1)
print("PASS  catalog jsonl")
PY
rm -f "$catalog_log"

echo "== 3. scaffold a module, the unit, and the stack."
mod="$(mktemp -d)"
(
  cd "$tmp/lab"
  terragrunt --no-color --non-interactive scaffold --root-file-name root.hcl --output-folder "$mod" ./catalog/modules/record
)
need "$mod/terragrunt.hcl" 'find_in_parent_folders\("root.hcl"\)' \
  'module scaffold should include root.hcl'
need "$mod/terragrunt.hcl" 'modules/record' \
  'module scaffold should point source at modules/record'
need "$mod/terragrunt.hcl" 'environment[[:space:]]*=[[:space:]]*""[[:space:]]*# TODO: fill in value' \
  'module scaffold should leave environment as a TODO'
pass "module scaffold"

unit_out="$(mktemp -d)"
stack_out="$(mktemp -d)"
(
  cd "$tmp/lab"
  terragrunt --no-color --non-interactive scaffold --root-file-name root.hcl --output-folder "$unit_out" ./catalog//units/record
  terragrunt --no-color --non-interactive scaffold --root-file-name root.hcl --output-folder "$stack_out" ./catalog//stacks/platform
)
terragrunt hcl fmt --no-color --working-dir "$unit_out" >/dev/null
terragrunt hcl fmt --no-color --working-dir "$stack_out" >/dev/null
if ! diff -q "$unit_out/terragrunt.hcl" live/terragrunt.hcl >/dev/null; then
  echo "FAIL  live/terragrunt.hcl is not the scaffold of catalog/units/record"
  diff -u "$unit_out/terragrunt.hcl" live/terragrunt.hcl || true
  exit 1
fi
if ! diff -q "$stack_out/terragrunt.stack.hcl" stamped/terragrunt.stack.hcl >/dev/null; then
  echo "FAIL  stamped/terragrunt.stack.hcl is not the scaffold of catalog/stacks/platform"
  diff -u "$stack_out/terragrunt.stack.hcl" stamped/terragrunt.stack.hcl || true
  exit 1
fi
pass "unit and stack scaffold"
rm -rf "$tmp" "$mod" "$unit_out" "$stack_out"

echo "== 4. Fill the scaffolded values. No TODO placeholders remain."
forbid live/terragrunt.values.hcl '"TODO"' \
  'replace the TODO values in live/terragrunt.values.hcl'
forbid stamped/terragrunt.values.hcl '"TODO"' \
  'replace the TODO values in stamped/terragrunt.values.hcl'
need live/terragrunt.values.hcl 'environment[[:space:]]*=[[:space:]]*"dev"' \
  'set live environment = "dev"'
need live/terragrunt.values.hcl 'prefix[[:space:]]*=[[:space:]]*"lab"' \
  'set live prefix = "lab"'
need live/terragrunt.values.hcl 'note[[:space:]]*=[[:space:]]*"scaffolded unit"' \
  'set live note = "scaffolded unit"'
need stamped/terragrunt.values.hcl 'environment[[:space:]]*=[[:space:]]*"dev"' \
  'set stamped environment = "dev"'
need stamped/terragrunt.values.hcl 'prefix[[:space:]]*=[[:space:]]*"stk"' \
  'set stamped prefix = "stk"'
pass "values filled"

echo "== 5. Plan and apply the scaffolded unit."
plan_log="$(mktemp)"
(
  cd live
  terragrunt --no-color --non-interactive run -- plan -input=false -no-color
) >"$plan_log" 2>&1
if [[ "$(plan_count "$plan_log")" -ne 1 ]]; then
  echo "FAIL  live plan was not 3 to add"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -q 'scaffolded unit' "$plan_log"; then
  echo "FAIL  live plan did not use note \"scaffolded unit\""
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
pass "live plan"
rm -f "$plan_log"
(
  cd live
  terragrunt --no-color --non-interactive run -- apply -auto-approve -input=false -no-color
)
note="$(
  cd live
  terragrunt --no-color output -raw note
)"
name="$(
  cd live
  terragrunt --no-color output -raw name
)"
if [[ "$note" != "scaffolded unit" ]]; then
  echo "FAIL  live note was '${note}'"
  exit 1
fi
if [[ ! "$name" =~ ^lab-[a-z]+-[a-z]+$ ]]; then
  echo "FAIL  live name was '${name}'"
  exit 1
fi
pass "live apply (${name})"
assert_engine live
(
  cd live
  terragrunt --no-color --non-interactive run -- destroy -auto-approve -input=false -no-color
)
pass "live destroy"

echo "== 6. Generate the scaffolded stack and plan its unit."
(
  cd stamped
  terragrunt --no-color stack generate
)
[[ -f stamped/.terragrunt-stack/record/terragrunt.hcl ]]
stack_plan="$(mktemp)"
(
  cd stamped
  terragrunt --no-color --non-interactive stack run -- plan -input=false -no-color
) >"$stack_plan" 2>&1
if [[ "$(plan_count "$stack_plan")" -ne 1 ]]; then
  echo "FAIL  stamped stack plan was not 3 to add"
  cat "$stack_plan"
  rm -f "$stack_plan"
  exit 1
fi
if ! grep -q 'prefix.*= "stk"' "$stack_plan"; then
  echo "FAIL  stamped plan did not use prefix stk"
  cat "$stack_plan"
  rm -f "$stack_plan"
  exit 1
fi
pass "stamped stack plan"
rm -f "$stack_plan"

clean_runtime
echo "PASS  07.6 scaffold"
