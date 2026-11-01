#!/usr/bin/env bash
# Plan every unit. Writes report.json and plan.log next to this lecture.
set -euo pipefail

cd "$(dirname "$0")/.."
rm -f report.json plan.log plan-comment.md

terragrunt --no-color --non-interactive run --all \
  --report-file report.json \
  --report-format json \
  -- plan -input=false -no-color \
  | tee plan.log
