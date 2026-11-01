#!/usr/bin/env bash
# 01.2 repo tour. Reads the repo on disk. Does not call AWS or install tools.
# The same script lives in start/ and solution/.
set -euo pipefail

cd "$(dirname "$0")"

pass() {
  echo "PASS  $*"
}

fail() {
  echo "FAIL  $*"
  exit 1
}

root="$(cd ../../../.. && pwd)"
[[ -f "$root/.mise.toml" ]] || fail "root .mise.toml not found from ${PWD}"
[[ -d "$root/labs/01-setup/01.2-repo-tour" ]] || fail "labs/01-setup/01.2-repo-tour not found under ${root}"

readme="../README.md"
[[ -f "$readme" ]] || fail "lecture README is missing"
grep -Fq '## Goal' "$readme" || fail "README should have a Goal section"
grep -Fq '## Steps' "$readme" || fail "README should have a Steps section"
grep -Fq 'terraform_binary' "$readme" || fail 'README should mention terraform_binary'
pass "README"

mise="$root/.mise.toml"
grep -Eq '^terragrunt[[:space:]]*=[[:space:]]*"prefix:1\.2"' "$mise" \
  || fail '.mise.toml should pin Terragrunt with prefix:1.2'
pass ".mise.toml pins Terragrunt 1.2"
grep -Eq '^terraform[[:space:]]*=[[:space:]]*"prefix:1\.17"' "$mise" \
  || fail '.mise.toml should pin Terraform with prefix:1.17'
pass ".mise.toml pins Terraform 1.17"
grep -Eq '^opentofu[[:space:]]*=[[:space:]]*"prefix:1\.13"' "$mise" \
  || fail '.mise.toml should pin OpenTofu with prefix:1.13'
pass ".mise.toml pins OpenTofu 1.13"
grep -Eq '^tflint[[:space:]]*=[[:space:]]*"0\.65\.0"' "$mise" \
  || fail '.mise.toml should pin tflint 0.65.0'
grep -Eq '^sops[[:space:]]*=[[:space:]]*"3\.13\.3"' "$mise" \
  || fail '.mise.toml should pin sops 3.13.3'
grep -Eq '^age[[:space:]]*=[[:space:]]*"1\.3\.2"' "$mise" \
  || fail '.mise.toml should pin age 1.3.2'
pass ".mise.toml pins tflint, sops, and age"

sections=(
  01-setup
  02-install
  03-core-hcl
  04-include
  05-remote-state
  06-dependencies
  07-stacks
  08-hooks
  09-secrets-multi-account
  10-cicd
  11-migrate-troubleshoot
  12-addon-opentofu
  13-capstone
)
for section in "${sections[@]}"; do
  [[ -d "$root/labs/$section" ]] || fail "missing labs/${section}"
done
pass "labs sections 01-13"

sample="$root/labs/03-core-hcl/03.2-locals-inputs"
[[ -f "$sample/README.md" ]] || fail "03.2-locals-inputs is missing README.md"
[[ -d "$sample/start" ]] || fail "03.2-locals-inputs is missing start/"
[[ -d "$sample/solution" ]] || fail "03.2-locals-inputs is missing solution/"
pass "03.2-locals-inputs has README, start, and solution"

clouds=(
  "labs/05-remote-state/05.2-backend-bootstrap"
  "labs/09-secrets-multi-account/09.2-assume-role"
  "labs/09-secrets-multi-account/09.3-multi-account"
  "labs/10-cicd/10.2-gha-oidc"
)
for cloud in "${clouds[@]}"; do
  [[ -f "$root/$cloud/README.md" ]] || fail "missing ${cloud}/README.md"
  [[ -d "$root/$cloud/start" && -d "$root/$cloud/solution" ]] \
    || fail "${cloud} should have start/ and solution/"
  head -n 1 "$root/$cloud/README.md" | grep -Fq '☁️' \
    || fail "${cloud} title should be cloud-marked"
  grep -Fq "$cloud" "$readme" || fail "this lecture README should document ${cloud}"
  if ! grep -F "$cloud" "$root/README.md" | grep -Fq '☁️'; then
    fail "root README should mark ${cloud} with the cloud icon"
  fi
done
pass "cloud lectures 05.2, 09.2, 09.3, 10.2"

if [[ -f checklist.md ]]; then
  pass "checklist"
elif [[ -f ../start/checklist.md ]]; then
  pass "checklist"
else
  fail "start/checklist.md is missing"
fi

if [[ -f NOTES.md ]]; then
  notes="NOTES.md"
else
  notes="../solution/NOTES.md"
fi
[[ -f "$notes" ]] || fail "solution/NOTES.md is missing"
for phrase in \
  "prefix:1.2" \
  "prefix:1.17" \
  "prefix:1.13" \
  "03.2-locals-inputs" \
  "05.2-backend-bootstrap" \
  "09.2-assume-role" \
  "09.3-multi-account" \
  "10.2-gha-oidc" \
  "terraform_binary" \
  "do not call AWS"
do
  grep -Fq "$phrase" "$notes" || fail "NOTES.md should record ${phrase}"
done
pass "NOTES.md"

echo "PASS  01.2 repo tour"
