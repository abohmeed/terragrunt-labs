#!/usr/bin/env bash
# 13.2 next. Reads the lecture README. Nothing is applied.
set -euo pipefail

cd "$(dirname "$0")"
readme="../README.md"

need() {
  local phrase="$1"
  if ! grep -Fq -- "$phrase" "$readme"; then
    echo "FAIL  README should mention ${phrase}"
    exit 1
  fi
}

need "13.1-capstone"
need "05.2-backend-bootstrap"
need "09.2-assume-role"
need "09.3-multi-account"
need "10.2-gha-oidc"
need "10.3-plan-on-pr"
need "10.4-apply-on-merge"
need "12.1-switch-to-tofu"
need "12.2-tofu-specifics"
need "OpenTofu 1.13"
need "render --format json"
need ".mise.toml"

echo "PASS  13.2 next"
