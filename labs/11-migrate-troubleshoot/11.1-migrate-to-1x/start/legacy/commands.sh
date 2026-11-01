#!/usr/bin/env bash
# Terragrunt 0.x queue. Leave this file. scripts/queue.sh is the 1.x replacement.
set -euo pipefail
cd "$(dirname "$0")"
terragrunt run-all plan \
  --terragrunt-non-interactive \
  --terragrunt-working-dir . \
  --terragrunt-tfpath terraform \
  --terragrunt-exclude-dir _envcommon \
  --terragrunt-log-level info
