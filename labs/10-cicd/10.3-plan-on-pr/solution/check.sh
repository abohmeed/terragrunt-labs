#!/usr/bin/env bash
# 10.3 plan on pull request. Re-runnable. Local backend. Does not call GitHub or AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache service/.terragrunt-cache state
rm -f report.json plan.log plan-comment.md

cleanup() {
  rm -rf network/.terragrunt-cache service/.terragrunt-cache state
  rm -f report.json plan.log plan-comment.md
}
trap cleanup EXIT

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

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Local backend, Terraform, and the network mock."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need root.hcl 'backend[[:space:]]*=[[:space:]]*"local"' \
  'set remote_state.backend to "local"'
need root.hcl 'path[[:space:]]*=[[:space:]]*"\$\{get_parent_terragrunt_dir\(\)\}/state/\$\{path_relative_to_include\(\)\}/terraform\.tfstate"' \
  'keep one local state file per unit'
forbid network/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid service/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need network/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"plan on pull request"' \
  'network note is plan on pull request'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'service should depend on ../network'
need service/terragrunt.hcl 'name[[:space:]]*=[[:space:]]*"mock-network-name"' \
  'service should mock the network name'
need service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
  'service note should be the network name output'
pass "units"

echo "== 3. plan.sh is the non-interactive queue, and it writes a JSON report."
need scripts/plan.sh '--non-interactive' \
  'plan.sh should pass --non-interactive'
need scripts/plan.sh 'run --all' \
  'plan.sh should run --all'
need scripts/plan.sh '--report-file report\.json' \
  'plan.sh should pass --report-file report.json'
need scripts/plan.sh '--report-format json' \
  'plan.sh should pass --report-format json'
need scripts/plan.sh '-- plan' \
  'plan.sh should run plan after --'
forbid scripts/plan.sh '-- apply' \
  'plan.sh plans. Apply belongs in lecture 10.4.'
need scripts/plan-comment.sh 'report\.json' \
  'plan-comment.sh should read report.json'
need scripts/plan-comment.sh 'plan-comment\.md' \
  'plan-comment.sh should write plan-comment.md'
need scripts/plan-comment.sh 'Plan:' \
  'plan-comment.sh should copy Plan lines into the comment'
pass "scripts"

echo "== 4. The workflow posts plan-comment.md on a pull request."
python3 - <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("FAIL  python3-yaml is required to read the workflow\n")
    sys.exit(1)

path = Path(".github/workflows/plan.yml")
raw = path.read_text()
if "TODO" in raw:
    sys.stderr.write("FAIL  replace the TODOs in .github/workflows/plan.yml\n")
    sys.exit(1)
for banned in (
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "aws-access-key-id",
    "aws-secret-access-key",
):
    if banned in raw:
        sys.stderr.write(f"FAIL  plan.yml must not contain {banned}\n")
        sys.exit(1)

text = re.sub(r"(?m)^on:", '"on":', raw, count=1)
doc = yaml.safe_load(text)
trigger = doc.get("on")
if not isinstance(trigger, dict) or "pull_request" not in trigger:
    sys.stderr.write("FAIL  plan.yml: on.pull_request\n")
    sys.exit(1)
if "push" in trigger:
    sys.stderr.write("FAIL  plan.yml runs on pull_request. Apply on main is lecture 10.4.\n")
    sys.exit(1)
perms = doc.get("permissions") or {}
if perms.get("contents") != "read" or perms.get("pull-requests") != "write":
    sys.stderr.write("FAIL  plan.yml permissions: contents read, pull-requests write\n")
    sys.exit(1)
if (doc.get("concurrency") or {}).get("cancel-in-progress") is not True:
    sys.stderr.write("FAIL  plan.yml: cancel-in-progress is true\n")
    sys.exit(1)

steps = ((doc.get("jobs") or {}).get("plan") or {}).get("steps") or []
if not any(str(step.get("uses", "")).startswith("actions/checkout@v7.0.1") for step in steps):
    sys.stderr.write("FAIL  plan.yml should use actions/checkout@v7.0.1\n")
    sys.exit(1)
runs = [str(step.get("run", "")) for step in steps]
if not any("./scripts/plan.sh" in item for item in runs):
    sys.stderr.write("FAIL  plan.yml should run ./scripts/plan.sh\n")
    sys.exit(1)
writers = [step for step in steps if "./scripts/plan-comment.sh" in str(step.get("run", ""))]
if len(writers) != 1 or writers[0].get("if") != "always()":
    sys.stderr.write("FAIL  the plan-comment step runs ./scripts/plan-comment.sh with if: always()\n")
    sys.exit(1)
posts = [step for step in steps if "gh pr comment" in str(step.get("run", ""))]
if len(posts) != 1:
    sys.stderr.write("FAIL  plan.yml should post with gh pr comment\n")
    sys.exit(1)
post = posts[0]
if "--body-file plan-comment.md" not in str(post.get("run")):
    sys.stderr.write("FAIL  gh pr comment should use --body-file plan-comment.md\n")
    sys.exit(1)
if "pull_request" not in str(post.get("if")):
    sys.stderr.write("FAIL  the comment step if: should include pull_request\n")
    sys.exit(1)
token = str((post.get("env") or {}).get("GH_TOKEN", ""))
if token != "${{ github.token }}":
    sys.stderr.write("FAIL  GH_TOKEN should be ${{ github.token }}\n")
    sys.exit(1)
PY
pass "plan.yml"

echo "== 5. Engine."
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

echo "== 6. run --all plan writes report.json."
./scripts/plan.sh
python3 - <<'PY'
import json
import sys
from pathlib import Path

rows = json.loads(Path("report.json").read_text())
names = sorted(row["Name"].strip().rstrip("/").split("/")[-1] for row in rows)
if names != ["network", "service"]:
    sys.stderr.write(f"FAIL  report units are {names}, expected network and service\n")
    sys.exit(1)
for row in rows:
    if row.get("Result") != "succeeded" or row.get("Cmd") != "plan":
        sys.stderr.write(f"FAIL  report row {row.get('Name')} result={row.get('Result')} cmd={row.get('Cmd')}\n")
        sys.exit(1)
PY
if ! grep -Fq "mock-network-name" plan.log; then
  echo "FAIL  service plan did not use mock-network-name"
  exit 1
fi
if ! grep -Fq "plan on pull request" plan.log; then
  echo "FAIL  network plan did not show note plan on pull request"
  exit 1
fi
pass "report.json"

echo "== 7. plan-comment.md is the comment body."
./scripts/plan-comment.sh
# The heading starts with '#', so this check does not use the comment-stripping grep.
if ! grep -Fq -- '## Terragrunt plan' plan-comment.md; then
  echo "FAIL  plan-comment.md should start with the plan heading"
  exit 1
fi
if ! grep -Fq -- '| `network` |' plan-comment.md; then
  echo "FAIL  plan-comment.md should name network"
  exit 1
fi
if ! grep -Fq -- '| `service` |' plan-comment.md; then
  echo "FAIL  plan-comment.md should name service"
  exit 1
fi
if ! grep -Fq -- 'succeeded' plan-comment.md; then
  echo "FAIL  plan-comment.md should record succeeded"
  exit 1
fi
if [[ "$(grep -c 'Plan: 3 to add, 0 to change, 0 to destroy.' plan-comment.md)" -lt 2 ]]; then
  echo "FAIL  plan-comment.md should include a 3-add plan for network and for service"
  exit 1
fi
if ! grep -Fq '[network]' plan-comment.md || ! grep -Fq '[service]' plan-comment.md; then
  echo "FAIL  plan-comment.md should keep the unit name on each Plan line"
  exit 1
fi
echo "== plan-comment.md"
cat plan-comment.md
pass "plan comment"

trap - EXIT
cleanup
echo "PASS  10.3 plan on pull request"
echo "GitHub was not contacted. plan-comment.md is the comment body the workflow would post."
