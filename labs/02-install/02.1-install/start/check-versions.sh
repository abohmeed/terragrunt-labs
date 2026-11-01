#!/usr/bin/env bash
# Confirm the course pins: Terragrunt 1.2.x and Terraform 1.17.x.
# Any patch on those minor versions passes.
set -euo pipefail

fail=0

require_version() {
  local bin="$1"
  local label="$2"
  local pattern="$3"
  shift 3

  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "FAIL  ${label}: '${bin}' is not on PATH"
    echo "      From the repo root: mise trust && mise install"
    echo "      Then: eval \"\$(mise activate bash)\"   or   mise exec -- ${bin} --version"
    fail=1
    return
  fi

  local out first
  out="$("$bin" "$@" 2>&1)" || true
  first="$(printf '%s\n' "$out" | head -n 1)"
  if printf '%s\n' "$out" | grep -Eq "$pattern"; then
    echo "PASS  ${label}: ${first}"
  else
    echo "FAIL  ${label}: expected a version matching ${pattern}"
    echo "      got: ${first}"
    fail=1
  fi
}

require_version terragrunt "Terragrunt 1.2.x" 'terragrunt version v1\.2\.[0-9]+' --version
require_version terraform "Terraform 1.17.x" 'Terraform v1\.17\.[0-9]+' version

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Pins match. OpenTofu may also be installed for section 12; leave it unused here."
