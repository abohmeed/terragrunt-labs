# 10.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  10.1 design
AWS was not contacted. This lecture stops at the design and the rendered config.
```

The checker does not apply, and it does not run the workflow.

`design.md` records plan on `pull_request` and apply on a push to `main`. `diagram.mmd` is the same path: pull request, plan, comment, `report.json`, OIDC into both jobs, merge, apply, provider cache.

`sample/root.hcl` holds `terraform_binary = "terraform"` and a local `remote_state` block. The path is `${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. `terragrunt run -- version` in `sample/dev` and `sample/prod` prints `Terraform v1.17.<patch>`.
3. `terragrunt render` in dev shows `backend = "local"` and a key ending in `sample/state/dev/terraform.tfstate`. Prod ends in `sample/state/prod/terraform.tfstate`. Both notes are `ci design`. `prefix` is `dev-lab` and `prod-lab`.
4. `terragrunt hcl validate --inputs --strict --tf-path terraform` reports that every variable is set.
5. `sample/.github/workflows/pipeline.yml` parses. Plan is gated on `pull_request` and passes `--report-file report.json`. Apply is gated on `refs/heads/main` and passes `--provider-cache`. `cancel-in-progress` is false. The file has no access key.

The workflow is a sketch. Lectures 10.2, 10.3, and 10.4 fill in OIDC, the report, the comment, and the cache.
