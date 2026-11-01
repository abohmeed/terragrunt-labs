#!/usr/bin/env bash
# Apply dev and prod. Local backend. The workflow's role step is not run here.
set -euo pipefail
cd "$(dirname "$0")/.."

for env in dev prod; do
  terragrunt --no-color --non-interactive --working-dir "live/${env}" \
    stack run --tf-path terraform -- apply -input=false -no-color
done
