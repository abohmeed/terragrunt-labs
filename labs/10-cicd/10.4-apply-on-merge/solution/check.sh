#!/usr/bin/env bash
# 10.4 apply on merge. Re-runnable. Local backend and the provider cache.
# The workflow's OIDC step is not executed. This script does not call AWS.
# Run this from start/ after the TODOs, or from solution/.
set -euo pipefail

cd "$(dirname "$0")"
rm -rf network/.terragrunt-cache service/.terragrunt-cache state .provider-cache
rm -f report.json

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
  terragrunt --no-color --non-interactive run --all -- destroy -input=false -no-color >/dev/null 2>&1 || true
  rm -rf network/.terragrunt-cache service/.terragrunt-cache state .provider-cache
  rm -f report.json
}

echo "== 1. HCL is formatted."
terragrunt hcl fmt --check --no-color
pass "fmt"

echo "== 2. Local backend, Terraform, and the dependency used at apply time."
need root.hcl '^terraform_binary[[:space:]]*=[[:space:]]*"terraform"' \
  'root.hcl should set terraform_binary = "terraform"'
need root.hcl 'backend[[:space:]]*=[[:space:]]*"local"' \
  'set remote_state.backend to "local"'
forbid network/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
forbid service/terragrunt.hcl '^terraform_binary[[:space:]]*=' \
  'leave terraform_binary in root.hcl'
need network/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*"apply on merge"' \
  'network note is apply on merge'
need service/terragrunt.hcl 'config_path[[:space:]]*=[[:space:]]*"\.\./network"' \
  'service should depend on ../network'
need service/terragrunt.hcl 'mock_outputs_allowed_terraform_commands[[:space:]]*=[[:space:]]*\["validate", "plan"\]' \
  'mocks stay off for apply'
need service/terragrunt.hcl 'note[[:space:]]*=[[:space:]]*dependency\.network\.outputs\.name' \
  'service note should be the network name output'
pass "units"

echo "== 3. apply.sh uses the provider cache and writes a report."
need scripts/apply.sh '--non-interactive' \
  'apply.sh should pass --non-interactive'
need scripts/apply.sh 'run --all' \
  'apply.sh should run --all'
need scripts/apply.sh '--tf-path terraform' \
  'apply.sh should pass --tf-path terraform so the cache server uses Terraform'
need scripts/apply.sh '--provider-cache' \
  'apply.sh should pass --provider-cache'
need scripts/apply.sh '--provider-cache-dir' \
  'apply.sh should pass --provider-cache-dir'
need scripts/apply.sh '--report-file report\.json' \
  'apply.sh should pass --report-file report.json'
need scripts/apply.sh '--report-format json' \
  'apply.sh should pass --report-format json'
need scripts/apply.sh '-- apply' \
  'apply.sh should run apply after --'
pass "apply.sh"

echo "== 4. The workflow applies on a push to main and assumes the apply role."
python3 - <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("FAIL  python3-yaml is required to read the workflow\n")
    sys.exit(1)

path = Path(".github/workflows/apply.yml")
raw = path.read_text()
if "TODO" in raw:
    sys.stderr.write("FAIL  replace the TODOs in .github/workflows/apply.yml\n")
    sys.exit(1)
if "pull_request" in raw:
    sys.stderr.write("FAIL  apply.yml must not run on pull_request\n")
    sys.exit(1)
for banned in (
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "aws-access-key-id",
    "aws-secret-access-key",
):
    if banned in raw:
        sys.stderr.write(f"FAIL  apply.yml must not contain {banned}\n")
        sys.exit(1)

text = re.sub(r"(?m)^on:", '"on":', raw, count=1)
doc = yaml.safe_load(text)
trigger = doc.get("on")
branches = ((trigger or {}).get("push") or {}).get("branches") if isinstance(trigger, dict) else None
if not branches or "main" not in branches:
    sys.stderr.write("FAIL  apply.yml: on.push.branches includes main\n")
    sys.exit(1)
perms = doc.get("permissions") or {}
if perms.get("id-token") != "write" or perms.get("contents") != "read":
    sys.stderr.write("FAIL  apply.yml permissions: id-token write, contents read\n")
    sys.exit(1)
concurrency = doc.get("concurrency") or {}
if concurrency.get("group") != "apply-main" or concurrency.get("cancel-in-progress") is not False:
    sys.stderr.write("FAIL  apply.yml concurrency group is apply-main and cancel-in-progress is false\n")
    sys.exit(1)

job = (doc.get("jobs") or {}).get("apply") or {}
if "refs/heads/main" not in str(job.get("if")):
    sys.stderr.write("FAIL  apply job if: should include refs/heads/main\n")
    sys.exit(1)
steps = job.get("steps") or []
if not any(str(step.get("uses", "")).startswith("actions/checkout@v7.0.1") for step in steps):
    sys.stderr.write("FAIL  apply.yml should use actions/checkout@v7.0.1\n")
    sys.exit(1)
auth = [
    step for step in steps
    if str(step.get("uses", "")).startswith("aws-actions/configure-aws-credentials@v6.3.0")
]
if len(auth) != 1:
    sys.stderr.write("FAIL  apply.yml: one aws-actions/configure-aws-credentials@v6.3.0 step\n")
    sys.exit(1)
assume = str((auth[0].get("with") or {}).get("role-to-assume", ""))
if "vars.AWS_APPLY_ROLE_ARN" not in assume:
    sys.stderr.write("FAIL  role-to-assume uses vars.AWS_APPLY_ROLE_ARN\n")
    sys.exit(1)
if (auth[0].get("with") or {}).get("aws-region") != "us-east-1":
    sys.stderr.write("FAIL  aws-region is us-east-1\n")
    sys.exit(1)
if not any(step.get("run") == "./scripts/apply.sh" for step in steps):
    sys.stderr.write("FAIL  apply.yml should run ./scripts/apply.sh\n")
    sys.exit(1)
PY
pass "apply.yml"

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

echo "== 6. Apply through the provider cache."
trap cleanup EXIT
apply_log="$(mktemp)"
./scripts/apply.sh 2>&1 | tee "$apply_log"
if ! grep -Fq "Terragrunt Cache server stopped" "$apply_log"; then
  echo "FAIL  the provider cache server did not run. Pass --tf-path terraform with --provider-cache."
  rm -f "$apply_log"
  exit 1
fi
rm -f "$apply_log"
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
    if row.get("Result") != "succeeded" or row.get("Cmd") != "apply":
        sys.stderr.write(f"FAIL  report row {row.get('Name')} result={row.get('Result')} cmd={row.get('Cmd')}\n")
        sys.exit(1)

cache = Path(".provider-cache")
for provider in ("local", "null", "random"):
    matches = list(cache.glob(f"registry.terraform.io/hashicorp/{provider}/*/*"))
    if not matches:
        sys.stderr.write(f"FAIL  provider cache is missing hashicorp/{provider}\n")
        sys.exit(1)
PY
pass "apply report"

echo "== 7. Apply used the network output, not the mock."
net_name="$(cd network && terragrunt --no-color output -raw name)"
net_note="$(cd network && terragrunt --no-color output -raw note)"
svc_note="$(cd service && terragrunt --no-color output -raw note)"
if [[ "$net_note" != "apply on merge" ]]; then
  echo "FAIL  network note is '${net_note}'"
  exit 1
fi
if [[ "$svc_note" != "$net_name" ]]; then
  echo "FAIL  service note '${svc_note}' is not the network name '${net_name}'"
  exit 1
fi
if [[ "$svc_note" == "mock-network-name" ]]; then
  echo "FAIL  service apply used the mock"
  exit 1
fi
pass "outputs"

echo "== 8. Destroy the queue."
destroy_log="$(mktemp)"
terragrunt --no-color --non-interactive run --all -- destroy -input=false -no-color >"$destroy_log" 2>&1
if [[ "$(grep -c 'Destroy complete' "$destroy_log")" -lt 2 ]]; then
  echo "FAIL  destroy did not complete for both units"
  cat "$destroy_log"
  rm -f "$destroy_log"
  exit 1
fi
pass "destroy"
rm -f "$destroy_log"

trap - EXIT
rm -rf network/.terragrunt-cache service/.terragrunt-cache state .provider-cache
rm -f report.json
echo "PASS  10.4 apply on merge"
echo "AWS was not contacted. The apply used the local backend. The workflow's role step is the cloud part."
