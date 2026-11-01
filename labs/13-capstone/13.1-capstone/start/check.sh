#!/usr/bin/env bash
# 13.1 capstone. Re-runnable. Local backend. The workflow role steps are not executed.
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

cleanup() {
  terragrunt --no-color --non-interactive --working-dir live/dev stack run --tf-path terraform -- destroy -input=false -no-color >/dev/null 2>&1 || true
  terragrunt --no-color --non-interactive --working-dir live/prod stack run --tf-path terraform -- destroy -input=false -no-color >/dev/null 2>&1 || true
  terragrunt --no-color --working-dir live/dev stack clean >/dev/null 2>&1 || true
  terragrunt --no-color --working-dir live/prod stack clean >/dev/null 2>&1 || true
  find . -type d \( -name .terragrunt-cache -o -name .terraform -o -name .terragrunt-stack \) -prune -exec rm -rf {} +
  rm -rf state
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

echo "== 2. Catalog, local backend, and Terraform."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need root.hcl 'backend[[:space:]]*=[[:space:]]*"local"' \
  'set remote_state.backend to local'
need root.hcl '"\./catalog"' \
  'set the catalog url to ./catalog'
forbid root.hcl 'github\.com' \
  'keep this lecture on the local catalog'
for env in dev prod; do
  need "live/${env}/terragrunt.stack.hcl" 'source[[:space:]]*=[[:space:]]*"\.\./\.\./catalog//units/record"' \
    "${env} should source ../../catalog//units/record"
  forbid "live/${env}/terragrunt.stack.hcl" '"TODO"' \
    "replace the TODO source in live/${env}"
  need "live/${env}/terragrunt.stack.hcl" 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
    "${env} service note should be the network name output"
  need "live/${env}/terragrunt.stack.hcl" 'name[[:space:]]*=[[:space:]]*"mock-network-name"' \
    "${env} should mock the network name"
done
need live/dev/terragrunt.stack.hcl 'note[[:space:]]*=[[:space:]]*"dev network"' \
  'dev network note should stay dev network'
need live/prod/terragrunt.stack.hcl 'note[[:space:]]*=[[:space:]]*"prod network"' \
  'prod network note should stay prod network'
pass "layout"

echo "== 3. terragrunt catalog lists the module, the unit, and the stack."
tmp="$(mktemp -d)"
python3 - "$tmp/lab" << 'PY'
import shutil
import sys
from pathlib import Path
dest = Path(sys.argv[1])
shutil.copytree(
    Path("."),
    dest,
    ignore=shutil.ignore_patterns(".terragrunt-cache", ".terraform", ".terragrunt-stack", "state"),
)
PY
git -C "$tmp/lab/catalog" init -q
catalog_log="$(mktemp)"
(
  cd "$tmp/lab"
  terragrunt --no-color catalog --format=jsonl --root-file-name root.hcl
) >"$catalog_log"
python3 - "$catalog_log" << 'PY'
import json
import sys
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
    ("stack", "stacks/env", "Environment"),
}
missing = need - found
if missing:
    print("FAIL  catalog entries missing: " + ", ".join(sorted(map(str, missing))))
    print("got: " + ", ".join(sorted(map(str, found))))
    sys.exit(1)
for row in rows:
    source = row.get("component_source") or ""
    if "//" not in source:
        print("FAIL  component_source has no // separator: " + source)
        sys.exit(1)
PY
pass "catalog"
rm -rf "$tmp" "$catalog_log"

echo "== 4. Scripts plan and apply both environments on the local backend."
for script in scripts/plan.sh scripts/apply.sh; do
  need "$script" '--non-interactive' \
    "${script} should pass --non-interactive"
  need "$script" '--tf-path terraform' \
    "${script} should pass --tf-path terraform"
  need "$script" 'stack run' \
    "${script} should use stack run"
  if ! grep -Fq 'live/${env}' "$script"; then
    echo "FAIL  ${script} should run live/dev and live/prod"
    exit 1
  fi
  if [[ ! -x "$script" ]]; then
    echo "FAIL  ${script} should be executable"
    exit 1
  fi
done
need scripts/plan.sh '-- plan' \
  'plan.sh should plan after --'
need scripts/apply.sh '-- apply' \
  'apply.sh should apply after --'
pass "scripts"

echo "== 5. Workflows keep the cloud role step commented out."
python3 - << 'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("FAIL  python3-yaml is required to read the workflow\n")
    sys.exit(1)

def active_lines(raw):
    return "\n".join(line for line in raw.splitlines() if not line.strip().startswith("#"))

def load(path):
    raw = Path(path).read_text()
    if "TODO" in raw:
        sys.stderr.write(f"FAIL  replace the TODOs in {path}\n")
        sys.exit(1)
    text = re.sub(r"(?m)^on:", '"on":', raw, count=1)
    return raw, yaml.safe_load(text)

raw, doc = load(".github/workflows/plan.yml")
active = active_lines(raw)
trigger = doc.get("on")
if not isinstance(trigger, dict) or "pull_request" not in trigger:
    sys.stderr.write("FAIL  plan.yml should run on pull_request\n")
    sys.exit(1)
if "push" in trigger:
    sys.stderr.write("FAIL  plan.yml should not run on push\n")
    sys.exit(1)
if "aws-actions" in active or "role-to-assume" in active:
    sys.stderr.write("FAIL  plan.yml role step should stay commented\n")
    sys.exit(1)
if "AWS_PLAN_ROLE_ARN" not in raw:
    sys.stderr.write("FAIL  plan.yml should document the stubbed plan role\n")
    sys.exit(1)
perms = doc.get("permissions") or {}
if perms.get("contents") != "read" or perms.get("id-token") != "write":
    sys.stderr.write("FAIL  plan.yml permissions: contents read, id-token write\n")
    sys.exit(1)
steps = ((doc.get("jobs") or {}).get("plan") or {}).get("steps") or []
if not any(step.get("run") == "./scripts/plan.sh" for step in steps):
    sys.stderr.write("FAIL  plan.yml should run ./scripts/plan.sh\n")
    sys.exit(1)
if not any(str(step.get("uses", "")).startswith("actions/checkout@v7.0.1") for step in steps):
    sys.stderr.write("FAIL  plan.yml should use actions/checkout@v7.0.1\n")
    sys.exit(1)

raw, doc = load(".github/workflows/apply.yml")
active = active_lines(raw)
if "pull_request" in raw:
    sys.stderr.write("FAIL  apply.yml must not mention pull_request\n")
    sys.exit(1)
trigger = doc.get("on")
branches = ((trigger or {}).get("push") or {}).get("branches") if isinstance(trigger, dict) else None
if not branches or "main" not in branches:
    sys.stderr.write("FAIL  apply.yml should push to main\n")
    sys.exit(1)
if "aws-actions" in active or "role-to-assume" in active:
    sys.stderr.write("FAIL  apply.yml role step should stay commented\n")
    sys.exit(1)
if "AWS_APPLY_ROLE_ARN" not in raw:
    sys.stderr.write("FAIL  apply.yml should document the stubbed apply role\n")
    sys.exit(1)
concurrency = doc.get("concurrency") or {}
if concurrency.get("group") != "apply-main" or concurrency.get("cancel-in-progress") is not False:
    sys.stderr.write("FAIL  apply.yml concurrency is apply-main and cancel-in-progress is false\n")
    sys.exit(1)
job = (doc.get("jobs") or {}).get("apply") or {}
if "refs/heads/main" not in str(job.get("if")):
    sys.stderr.write("FAIL  apply job if should include refs/heads/main\n")
    sys.exit(1)
steps = job.get("steps") or []
if not any(step.get("run") == "./scripts/apply.sh" for step in steps):
    sys.stderr.write("FAIL  apply.yml should run ./scripts/apply.sh\n")
    sys.exit(1)
PY
pass "workflows"

echo "== 6. Plan both environments. Service uses the mock."
plan_log="$(mktemp)"
set +e
./scripts/plan.sh >"$plan_log" 2>&1
plan_status=$?
set -e
if [[ "$plan_status" -ne 0 ]]; then
  echo "FAIL  scripts/plan.sh exited ${plan_status}"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
plan_count="$(grep -c "Plan: 3 to add, 0 to change, 0 to destroy." "$plan_log" || true)"
if [[ "$plan_count" -ne 4 ]]; then
  echo "FAIL  expected 4 plans that add 3 resources, saw ${plan_count}"
  cat "$plan_log"
  rm -f "$plan_log"
  exit 1
fi
if [[ "$(grep -c 'mock-network-name' "$plan_log")" -lt 2 ]]; then
  echo "FAIL  both service plans should use mock-network-name"
  rm -f "$plan_log"
  exit 1
fi
if ! grep -Fq '"dev network"' "$plan_log" || ! grep -Fq '"prod network"' "$plan_log"; then
  echo "FAIL  network plans should show dev network and prod network"
  rm -f "$plan_log"
  exit 1
fi
pass "plan"
rm -f "$plan_log"

echo "== 7. Apply, read both stacks, and destroy."
./scripts/apply.sh
python3 - << 'PY'
import json
import subprocess
import sys

errors = []
for env, prefix, note in (("dev", "dev-", "dev network"), ("prod", "prd-", "prod network")):
    raw = subprocess.check_output(
        [
            "terragrunt",
            "--no-color",
            "--working-dir",
            f"live/{env}",
            "stack",
            "output",
            "--format",
            "json",
            "--tf-path",
            "terraform",
        ],
        text=True,
    )
    data = json.loads(raw)
    network = data["network"]
    service = data["service"]
    if network["note"] != note or network["environment"] != env:
        errors.append(f"{env} network was {network['note']!r} {network['environment']!r}")
    if not str(network["name"]).startswith(prefix):
        errors.append(f"{env} network name was {network['name']!r}")
    if service["note"] != network["name"]:
        errors.append(f"{env} service note {service['note']!r} is not {network['name']!r}")
    if service["note"] == "mock-network-name":
        errors.append(f"{env} service note is still the mock")
    if service["prefix"] != "svc" or service["environment"] != env:
        errors.append(f"{env} service inputs were {service['prefix']!r} {service['environment']!r}")
if errors:
    print("FAIL  " + "; ".join(errors))
    sys.exit(1)
print("PASS  service notes follow the network names")
PY

engine_log="$(mktemp)"
(
  cd live/dev/.terragrunt-stack/network
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

if ! find state -name terraform.tfstate | grep -q .; then
  echo "FAIL  local state files were not written under state/"
  exit 1
fi
pass "local state"

cleanup
echo "PASS  13.1 capstone"
echo "AWS was not contacted. The apply used the local backend. The workflow role steps stay commented."
