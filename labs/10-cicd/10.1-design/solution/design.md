# Pipeline design

## Plan

- Trigger: `pull_request`
- Command: `terragrunt --non-interactive run --all --report-file report.json -- plan -input=false`
- Comment: post `plan-comment.md` on the pull request
- Report: `report.json` from `--report-file`

## Apply

- Trigger: `push` to `main` after the pull request merges
- Command: `terragrunt --non-interactive run --all --provider-cache -- apply -input=false`
- Cache: Terragrunt provider cache (`--provider-cache`)

## Auth

- Method: GitHub Actions OIDC (`id-token: write`)
- Stored keys: none

## State

- Lab backend: `local`
- Key: `state/${path_relative_to_include()}/terraform.tfstate`
