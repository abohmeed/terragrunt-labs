# 10.4 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  10.4 apply on merge
AWS was not contacted. The apply used the local backend. The workflow's role step is the cloud part.
```

The checker does not call AWS and does not run the workflow. It runs `scripts/apply.sh`, checks outputs, destroys both units, and deletes `.provider-cache`.

`scripts/apply.sh` runs:

```bash
terragrunt --no-color --non-interactive run --all \
  --tf-path terraform \
  --provider-cache \
  --provider-cache-dir "${PWD}/.provider-cache" \
  --report-file report.json \
  --report-format json \
  -- apply -input=false -no-color
```

`--tf-path terraform` configures the provider cache server for Terraform. `tofu` is on `PATH` in this course. `terraform_binary = "terraform"` selects the unit engine and does not, by itself, select the cache server's binary.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
2. `.github/workflows/apply.yml` triggers on a push to `main`, sets `id-token: write`, keeps `cancel-in-progress` false on the group `apply-main`, assumes `vars.AWS_APPLY_ROLE_ARN`, and runs `./scripts/apply.sh`. It has no `pull_request` trigger and no access key.
3. The apply log contains `Terragrunt Cache server stopped`. `report.json` lists `network` and `service` with `"Result": "succeeded"` and `"Cmd": "apply"`.
4. `.provider-cache/registry.terraform.io/hashicorp/` contains `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. `Installed ... (unauthenticated)` is Terraform taking the provider from that server. The lock file still pins the hashes.
5. Network's note is `apply on merge`. Service's note equals the network name (`net-<word>-<word>`). It is not `mock-network-name`.
6. `terragrunt run --all -- destroy` reports `Destroy complete` for both units.

`run --all apply` adds `-auto-approve`. The run summary reports `Succeeded 2`.
