# 10.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  10.3 plan on pull request
GitHub was not contacted. plan-comment.md is the comment body the workflow would post.
```

The checker does not call GitHub. It prints `plan-comment.md`, then deletes that file, `plan.log`, and `report.json`.

The queue is `network`, then `service`. Service mocks the network name as `mock-network-name` for `validate` and `plan`. Network's note is `plan on pull request`.

`scripts/plan.sh` runs:

```bash
terragrunt --no-color --non-interactive run --all \
  --report-file report.json \
  --report-format json \
  -- plan -input=false -no-color
```

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
2. `.github/workflows/plan.yml` triggers on `pull_request`, sets `pull-requests: write`, runs `./scripts/plan.sh`, writes the comment with `if: always()`, and posts it with `gh pr comment --body-file plan-comment.md` using `GH_TOKEN: ${{ github.token }}`.
3. `report.json` is a JSON array. `network` and `service` each have `"Result": "succeeded"` and `"Cmd": "plan"`.
4. The plan log shows `mock-network-name` for service and `plan on pull request` for network. Each plan is `Plan: 3 to add, 0 to change, 0 to destroy.`
5. `plan-comment.md` starts with `## Terragrunt plan`, has a row for each unit, and copies both `Plan:` lines, including `[network]` and `[service]`.

`run --all` stays inside this directory. The run summary reports `Succeeded 2`.
