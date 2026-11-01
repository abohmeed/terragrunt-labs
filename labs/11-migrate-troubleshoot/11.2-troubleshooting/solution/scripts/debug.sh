#!/usr/bin/env bash
# Debug discovery, then render the generated unit.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf live/.terragrunt-stack

terragrunt --no-color --log-level debug --working-dir live stack generate --tf-path terraform
terragrunt --no-color --log-level debug --working-dir live/.terragrunt-stack/record \
  render --format json --tf-path terraform
