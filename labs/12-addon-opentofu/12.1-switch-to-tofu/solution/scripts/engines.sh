#!/usr/bin/env bash
# Show which binary each selector uses. The attribute is tofu.
# --tf-path and TG_TF_PATH override it for one command.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== attribute =="
terragrunt --no-color --working-dir unit run -- version

echo "== flag =="
terragrunt --no-color --working-dir unit run --tf-path terraform -- version

echo "== env =="
TG_TF_PATH=terraform terragrunt --no-color --working-dir unit run -- version
