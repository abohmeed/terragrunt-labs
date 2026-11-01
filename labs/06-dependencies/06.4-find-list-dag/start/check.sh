#!/usr/bin/env bash
# 06.4 find, list, and dag graph check. Re-runnable.
# Run this from start/ or from solution/. Discovery does not apply units.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache database/.terragrunt-cache service/.terragrunt-cache audit/.terragrunt-cache

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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. audit has no dependency. database and service form the chain."
forbid audit/terragrunt.hcl 'dependency[[:space:]]+"' \
  'leave the dependency block off audit/'
need database/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'database should depend on ../network'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./database"' \
  'service should depend on ../database'
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
pass "units"

echo "== 3. Engine."
version_log="$(mktemp)"
(
  cd network
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
pass "engine"
rm -f "$version_log"

echo "== 4. find"
found="$(terragrunt --no-color --non-interactive find)"
expected=$'audit\ndatabase\nnetwork\nservice'
if [[ "$found" != "$expected" ]]; then
  echo "FAIL  find listed:"
  printf '%s\n' "$found"
  exit 1
fi
pass "find"

echo "== 5. find --json --dependencies"
terragrunt --no-color --non-interactive find --json --dependencies >"${TMPDIR:-/tmp}/06.4-find.json"
python3 - "${TMPDIR:-/tmp}/06.4-find.json" <<'PY'
import json, sys
rows = json.load(open(sys.argv[1], encoding="utf-8"))
got = {row["path"]: row.get("dependencies", []) for row in rows}
expect = {
    "audit": [],
    "network": [],
    "database": ["network"],
    "service": ["database"],
}
if got != expect:
    print("FAIL  find --json dependencies were", got)
    sys.exit(1)
PY
pass "find json"
rm -f "${TMPDIR:-/tmp}/06.4-find.json"

echo "== 6. list --dag"
listed="$(terragrunt --no-color --non-interactive list --dag | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
if [[ "$listed" != "audit network database service" ]]; then
  echo "FAIL  list --dag was '${listed}'"
  exit 1
fi
pass "list --dag"

echo "== 7. list --long --dependencies --dag"
terragrunt --no-color --non-interactive list --long --dependencies --dag >"${TMPDIR:-/tmp}/06.4-long.txt"
python3 - "${TMPDIR:-/tmp}/06.4-long.txt" <<'PY'
import sys
rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    parts = line.split()
    if not parts or parts[0] == "Type":
        continue
    if parts[0] != "unit":
        print("FAIL  unexpected list row", line.rstrip())
        sys.exit(1)
    rows.append((parts[1], parts[2] if len(parts) > 2 else ""))
expect = [
    ("audit", ""),
    ("network", ""),
    ("database", "network"),
    ("service", "database"),
]
if rows != expect:
    print("FAIL  long list was", rows)
    sys.exit(1)
PY
pass "list long"
rm -f "${TMPDIR:-/tmp}/06.4-long.txt"

echo "== 8. list --tree --dag"
tree="$(terragrunt --no-color --non-interactive list --tree --dag)"
expected_tree=$'.\n├── audit\n╰── network\n    ╰── database\n        ╰── service'
if [[ "$tree" != "$expected_tree" ]]; then
  echo "FAIL  list --tree --dag was:"
  printf '%s\n' "$tree"
  exit 1
fi
pass "list tree"

echo "== 9. dag graph"
graph="$(terragrunt --no-color --non-interactive dag graph)"
python3 - "$graph" <<'PY'
import sys
text = sys.argv[1]
for edge in ('"database" -> "network";', '"service" -> "database";', '"audit" ;', '"network" ;'):
    if edge not in text:
        print("FAIL  dag graph missing", edge)
        print(text)
        sys.exit(1)
if not text.lstrip().startswith("digraph"):
    print("FAIL  dag graph did not start with digraph")
    sys.exit(1)
PY
pass "dag graph"

rm -rf network/.terragrunt-cache database/.terragrunt-cache service/.terragrunt-cache audit/.terragrunt-cache
echo "PASS  06.4 find, list, and the dag"
