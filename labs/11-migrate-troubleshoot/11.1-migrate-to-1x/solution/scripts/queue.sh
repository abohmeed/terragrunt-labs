#!/usr/bin/env bash
# 1.x queue. run --all replaces run-all. The terragrunt- prefix is gone.
set -euo pipefail
cd "$(dirname "$0")/.."

terragrunt --no-color --non-interactive \
  run --all \
  --tf-path terraform \
  --queue-exclude-dir 'legacy/**' \
  --queue-exclude-dir 'units/**' \
  -- plan -input=false -no-color
