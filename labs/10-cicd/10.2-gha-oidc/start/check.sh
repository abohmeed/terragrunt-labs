#!/usr/bin/env bash
# 10.2 GitHub Actions OIDC check. Re-runnable. Workflow and trust policy only.
# This script does not call AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"

pass() {
  echo "PASS  $*"
}

need() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! grep -Eq "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. terraform_binary stays on Terraform."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
pass "terraform_binary"

echo "== 3. Trust policies allow the two subjects and no one else."
python3 - <<'PY'
import json
import re
import sys
from pathlib import Path

def load(path):
    try:
        return json.loads(Path(path).read_text())
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"FAIL  {path} is not valid JSON: {exc}\n")
        sys.exit(1)

def check(path, sid_role, subject_pattern):
    raw = Path(path).read_text()
    if "TODO" in raw:
        sys.stderr.write(f"FAIL  replace the TODOs in {path}\n")
        sys.exit(1)
    if "*" in raw:
        sys.stderr.write(f"FAIL  {path} must not use a wildcard subject\n")
        sys.exit(1)
    doc = load(path)
    if doc.get("Version") != "2012-10-17":
        sys.stderr.write(f"FAIL  {path}: Version is 2012-10-17\n")
        sys.exit(1)
    statements = doc.get("Statement") or []
    if len(statements) != 1:
        sys.stderr.write(f"FAIL  {path}: one statement\n")
        sys.exit(1)
    statement = statements[0]
    if statement.get("Effect") != "Allow":
        sys.stderr.write(f"FAIL  {path}: Effect Allow\n")
        sys.exit(1)
    if statement.get("Action") != "sts:AssumeRoleWithWebIdentity":
        sys.stderr.write(f"FAIL  {path}: Action sts:AssumeRoleWithWebIdentity\n")
        sys.exit(1)
    federated = (statement.get("Principal") or {}).get("Federated", "")
    if not re.fullmatch(r"arn:aws:iam::\d{12}:oidc-provider/token\.actions\.githubusercontent\.com", federated):
        sys.stderr.write(f"FAIL  {path}: Federated principal is the GitHub OIDC provider\n")
        sys.exit(1)
    if "StringLike" in (statement.get("Condition") or {}):
        sys.stderr.write(f"FAIL  {path}: use StringEquals for the subject\n")
        sys.exit(1)
    equals = (statement.get("Condition") or {}).get("StringEquals") or {}
    aud = equals.get("token.actions.githubusercontent.com:aud")
    sub = equals.get("token.actions.githubusercontent.com:sub")
    if aud != "sts.amazonaws.com":
        sys.stderr.write(f"FAIL  {path}: audience is sts.amazonaws.com\n")
        sys.exit(1)
    if not isinstance(sub, str) or not re.fullmatch(subject_pattern, sub):
        sys.stderr.write(f"FAIL  {path}: subject does not match {subject_pattern}\n")
        sys.exit(1)
    print(f"PASS  {sid_role} trust")

check(
    "iam/plan-trust.json",
    "plan",
    r"repo:[^/]+/[^:]+:pull_request",
)
check(
    "iam/apply-trust.json",
    "apply",
    r"repo:[^/]+/[^:]+:ref:refs/heads/main",
)
PY

echo "== 4. The workflow asks for an OIDC token and assumes a role. No access keys."
python3 - <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("FAIL  python3-yaml is required to read the workflow\n")
    sys.exit(1)

path = Path(".github/workflows/oidc.yml")
raw = path.read_text()
if "TODO" in raw:
    sys.stderr.write("FAIL  replace the TODOs in .github/workflows/oidc.yml\n")
    sys.exit(1)
for banned in (
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "aws-access-key-id",
    "aws-secret-access-key",
):
    if banned in raw:
        sys.stderr.write(f"FAIL  oidc.yml must not contain {banned}\n")
        sys.exit(1)

text = re.sub(r"(?m)^on:", '"on":', raw, count=1)
doc = yaml.safe_load(text)
trigger = doc.get("on")
if not isinstance(trigger, dict) or "workflow_dispatch" not in trigger:
    sys.stderr.write("FAIL  oidc.yml: on.workflow_dispatch\n")
    sys.exit(1)
perms = doc.get("permissions") or {}
if perms.get("id-token") != "write":
    sys.stderr.write("FAIL  oidc.yml: permissions.id-token is write\n")
    sys.exit(1)
if perms.get("contents") != "read":
    sys.stderr.write("FAIL  oidc.yml: permissions.contents is read\n")
    sys.exit(1)

jobs = doc.get("jobs") or {}
expected = {
    "plan-auth": "vars.AWS_PLAN_ROLE_ARN",
    "apply-auth": "vars.AWS_APPLY_ROLE_ARN",
}
if set(jobs) != set(expected):
    sys.stderr.write("FAIL  oidc.yml jobs are plan-auth and apply-auth\n")
    sys.exit(1)

for name, role in expected.items():
    steps = jobs[name].get("steps") or []
    uses = [step.get("uses", "") for step in steps]
    if not any(item.startswith("actions/checkout@v7.0.1") for item in uses):
        sys.stderr.write(f"FAIL  {name}: uses actions/checkout@v7.0.1\n")
        sys.exit(1)
    auth = [
        step for step in steps
        if str(step.get("uses", "")).startswith("aws-actions/configure-aws-credentials@v6.3.0")
    ]
    if len(auth) != 1:
        sys.stderr.write(f"FAIL  {name}: one aws-actions/configure-aws-credentials@v6.3.0 step\n")
        sys.exit(1)
    with_ = auth[0].get("with") or {}
    assume = str(with_.get("role-to-assume", ""))
    if role not in assume:
        sys.stderr.write(f"FAIL  {name}: role-to-assume uses {role}\n")
        sys.exit(1)
    if with_.get("aws-region") != "us-east-1":
        sys.stderr.write(f"FAIL  {name}: aws-region is us-east-1\n")
        sys.exit(1)
    session = str(with_.get("role-session-name", ""))
    if not session or "TODO" in session:
        sys.stderr.write(f"FAIL  {name}: set role-session-name\n")
        sys.exit(1)
    runs = [step.get("run", "") for step in steps]
    if not any("aws sts get-caller-identity" in item for item in runs):
        sys.stderr.write(f"FAIL  {name}: show the caller with aws sts get-caller-identity\n")
        sys.exit(1)
PY
pass "oidc.yml"

echo "PASS  10.2 github actions oidc"
echo "AWS was not contacted. Follow the README to create the provider and the roles when you have an account."
