#!/usr/bin/env bash
# Apply every unit through the provider cache. The backend in root.hcl is local.
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p .provider-cache
rm -f report.json

terragrunt --no-color --non-interactive run --all \
  --tf-path terraform \
  --provider-cache \
  --provider-cache-dir "${PWD}/.provider-cache" \
  --report-file report.json \
  --report-format json \
  -- apply -input=false -no-color
