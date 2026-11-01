#!/usr/bin/env bash
# 10.1 design check. Re-runnable. Docs and sample config only. No AWS, no apply.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf sample/dev/.terragrunt-cache sample/prod/.terragrunt-cache sample/state

pass() {
  echo "PASS  $*"
}

need() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

need_line() {
  local file="$1"
  local line="$2"
  local message="$3"
  if ! grep -Fxq -- "$line" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

forbid() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if grep -Eq -- "$pattern" "$file"; then
    echo "FAIL  ${message}"
    exit 1
  fi
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. design.md records the pipeline."
need_line design.md '- Trigger: `pull_request`' \
  'design.md: plan trigger is pull_request'
need_line design.md '- Command: `terragrunt --non-interactive run --all --report-file report.json -- plan -input=false`' \
  'design.md: plan command'
need_line design.md '- Comment: post `plan-comment.md` on the pull request' \
  'design.md: plan comment'
need_line design.md '- Report: `report.json` from `--report-file`' \
  'design.md: report file'
need_line design.md '- Trigger: `push` to `main` after the pull request merges' \
  'design.md: apply trigger'
need_line design.md '- Command: `terragrunt --non-interactive run --all --provider-cache -- apply -input=false`' \
  'design.md: apply command'
need_line design.md '- Cache: Terragrunt provider cache (`--provider-cache`)' \
  'design.md: provider cache'
need_line design.md '- Method: GitHub Actions OIDC (`id-token: write`)' \
  'design.md: OIDC'
need_line design.md '- Stored keys: none' \
  'design.md: stored keys'
need_line design.md '- Lab backend: `local`' \
  'design.md: local backend'
need_line design.md '- Key: `state/${path_relative_to_include()}/terraform.tfstate`' \
  'design.md: state key'
forbid design.md 'TODO' 'replace the TODOs in design.md'
pass "design.md"

echo "== 3. diagram.mmd is the same path."
need diagram.mmd '^flowchart LR$' 'diagram.mmd should start with flowchart LR'
need diagram.mmd 'Pull request' 'diagram.mmd: Pull request'
need diagram.mmd 'terragrunt plan' 'diagram.mmd: terragrunt plan'
need diagram.mmd 'plan comment' 'diagram.mmd: plan comment'
need diagram.mmd 'report\.json' 'diagram.mmd: report.json'
need diagram.mmd 'OIDC' 'diagram.mmd: OIDC'
need diagram.mmd 'Merge to main' 'diagram.mmd: Merge to main'
need diagram.mmd 'terragrunt apply' 'diagram.mmd: terragrunt apply'
need diagram.mmd 'provider cache' 'diagram.mmd: provider cache'
need diagram.mmd 'oidc\["OIDC"\] --> plan' 'diagram.mmd: OIDC feeds the plan'
need diagram.mmd 'oidc --> apply' 'diagram.mmd: OIDC feeds the apply'
arrows="$(grep -o -- '-->' diagram.mmd | wc -l | tr -d ' ')"
if [[ "$arrows" -lt 7 ]]; then
  echo "FAIL  diagram.mmd needs an arrow for each step. Found ${arrows}."
  exit 1
fi
forbid diagram.mmd 'TODO' 'replace the TODOs in diagram.mmd'
pass "diagram"

echo "== 4. The sample workflow is the sketch, not a live run."
python3 - <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("FAIL  python3-yaml is required to read the workflow\n")
    sys.exit(1)

path = Path("sample/.github/workflows/pipeline.yml")
raw = path.read_text()
if "TODO" in raw:
    sys.stderr.write("FAIL  replace the TODOs in sample/.github/workflows/pipeline.yml\n")
    sys.exit(1)
for banned in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "aws-access-key-id", "aws-secret-access-key"):
    if banned in raw:
        sys.stderr.write(f"FAIL  pipeline.yml must not contain {banned}\n")
        sys.exit(1)

text = re.sub(r"(?m)^on:", '"on":', raw, count=1)
doc = yaml.safe_load(text)
trigger = doc.get("on")
if not isinstance(trigger, dict) or "pull_request" not in trigger:
    sys.stderr.write("FAIL  pipeline.yml: on.pull_request is the plan trigger\n")
    sys.exit(1)
branches = ((trigger.get("push") or {}).get("branches")) or []
if "main" not in branches:
    sys.stderr.write("FAIL  pipeline.yml: on.push.branches includes main\n")
    sys.exit(1)

perms = doc.get("permissions") or {}
if perms.get("contents") != "read" or perms.get("id-token") != "write" or perms.get("pull-requests") != "write":
    sys.stderr.write("FAIL  pipeline.yml permissions: contents read, id-token write, pull-requests write\n")
    sys.exit(1)
if (doc.get("concurrency") or {}).get("cancel-in-progress") is not False:
    sys.stderr.write("FAIL  pipeline.yml: cancel-in-progress is false so an apply is not cancelled\n")
    sys.exit(1)

jobs = doc.get("jobs") or {}
plan = jobs.get("plan") or {}
apply = jobs.get("apply") or {}
if "pull_request" not in str(plan.get("if")):
    sys.stderr.write("FAIL  plan job if: should include pull_request\n")
    sys.exit(1)
if "refs/heads/main" not in str(apply.get("if")):
    sys.stderr.write("FAIL  apply job if: should include refs/heads/main\n")
    sys.exit(1)

def run_of(job):
    for step in job.get("steps") or []:
        if step.get("run"):
            return step["run"]
    return ""

plan_run = run_of(plan)
apply_run = run_of(apply)
for piece in ("--non-interactive", "run --all", "--report-file report.json", "-- plan"):
    if piece not in plan_run:
        sys.stderr.write(f"FAIL  plan step is missing {piece}\n")
        sys.exit(1)
for piece in ("--non-interactive", "run --all", "--provider-cache", "-- apply"):
    if piece not in apply_run:
        sys.stderr.write(f"FAIL  apply step is missing {piece}\n")
        sys.exit(1)
if "actions/checkout@v7.0.1" not in raw:
    sys.stderr.write("FAIL  pipeline.yml should use actions/checkout@v7.0.1\n")
    sys.exit(1)
PY
pass "pipeline.yml"

echo "== 5. Sample root.hcl is a local backend. terraform_binary stays in the root."
need sample/root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'sample/root.hcl should set terraform_binary = "terraform"'
need sample/root.hcl 'backend[[:space:]]*=[[:space:]]*"local"' \
  'set remote_state.backend to "local"'
need sample/root.hcl 'path[[:space:]]*=[[:space:]]*"backend\.tf"' \
  'generate backend.tf from remote_state'
need sample/root.hcl 'if_exists[[:space:]]*=[[:space:]]*"overwrite_terragrunt"' \
  'set generate.if_exists to overwrite_terragrunt'
need sample/root.hcl 'path[[:space:]]*=[[:space:]]*"\$\{get_parent_terragrunt_dir\(\)\}/state/\$\{path_relative_to_include\(\)\}/terraform\.tfstate"' \
  'set the state path to ${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate'
forbid sample/root.hcl 'backend[[:space:]]*=[[:space:]]*"s3"' \
  'this lecture uses the local backend'
forbid sample/root.hcl 'TODO' 'replace the TODO state path'
forbid sample/dev/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid sample/prod/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
pass "root.hcl"

run_unit() {
  local dir="$1"
  local environment="$2"
  local prefix="$3"
  local state_file
  state_file="$(pwd)/sample/state/${dir}/terraform.tfstate"

  echo "== sample/${dir}: engine"
  local version_log
  version_log="$(mktemp)"
  (
    cd "sample/${dir}"
    terragrunt --no-color run -- version
  ) 2>&1 | tee "$version_log"
  if ! grep -q "Terraform v1\.17\." "$version_log"; then
    echo "FAIL  ${dir}: engine was not Terraform 1.17.x"
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

  echo "== sample/${dir}: render (no apply)"
  local render_log
  render_log="$(mktemp)"
  (
    cd "sample/${dir}"
    terragrunt --no-color render
  ) | tee "$render_log"
  if ! grep -Fq "path = \"${state_file}\"" "$render_log"; then
    echo "FAIL  ${dir}: render path is not ${state_file}"
    rm -f "$render_log"
    exit 1
  fi
  need "$render_log" 'backend[[:space:]]*=[[:space:]]*"local"' "${dir} render: local backend"
  need "$render_log" "environment[[:space:]]*=[[:space:]]*\"${environment}\"" "${dir} render: environment"
  need "$render_log" "prefix[[:space:]]*=[[:space:]]*\"${prefix}\"" "${dir} render: prefix"
  need "$render_log" 'note[[:space:]]*=[[:space:]]*"ci design"' "${dir} render: note"
  pass "${dir} render"
  rm -f "$render_log"

  echo "== sample/${dir}: inputs match the module variables."
  (
    cd "sample/${dir}"
    terragrunt hcl validate --inputs --strict --tf-path terraform --no-color
  )
  pass "${dir} inputs"
}

run_unit dev dev dev-lab
run_unit prod prod prod-lab

rm -rf sample/dev/.terragrunt-cache sample/prod/.terragrunt-cache sample/state
echo "PASS  10.1 design"
echo "AWS was not contacted. This lecture stops at the design and the rendered config."
