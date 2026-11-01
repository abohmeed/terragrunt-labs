# 10.4 Apply on merge

Apply the queue after the pull request merges, and download each provider once. The lab target is the local backend. The workflow stub includes the OIDC step from lecture 10.2. That step is ☁️. `./check.sh` runs the apply script and does not call AWS.

## Goal

From `start/`, make `./check.sh` pass. The units are already written. You add `scripts/apply.sh` and `.github/workflows/apply.yml`.

The apply queues `network`, then `service`. Service's `note` becomes the network `name`. The mock is not used, because `mock_outputs_allowed_terraform_commands` is `validate` and `plan`. The provider cache holds `local`, `null`, and `random`. The report lists both units as `succeeded` with `Cmd` `apply`. The checker then destroys the queue.

## The command

```bash
terragrunt --no-color --non-interactive run --all \
  --tf-path terraform \
  --provider-cache \
  --provider-cache-dir "${PWD}/.provider-cache" \
  --report-file report.json \
  --report-format json \
  -- apply -input=false -no-color
```

`run --all apply` adds `-auto-approve`. `-input=false` answers Terraform.

`--tf-path terraform` matters in this course because `tofu` is also on `PATH`. The provider cache server picks its binary at startup from `--tf-path`, `TG_TF_PATH`, or the first of `tofu` and `terraform`. `terraform_binary = "terraform"` selects the engine for the unit. It does not select the binary the cache server was configured with. When those two differ, Terragrunt skips the cache for that run. `--tf-path terraform` points both at Terraform 1.17. It also overrides `terraform_binary` for the run, with the same binary.

`--provider-cache` starts a cache server on localhost. Each provider is stored once under `.provider-cache/`:

```text
.provider-cache/registry.terraform.io/hashicorp/random/3.9.1/linux_amd64/
.provider-cache/registry.terraform.io/hashicorp/null/3.3.2/linux_amd64/
.provider-cache/registry.terraform.io/hashicorp/local/2.9.1/linux_amd64/
```

The log line `Terragrunt Cache server stopped` means the server ran and shut down after the queue. `Installed hashicorp/random v3.9.1 (unauthenticated)` means Terraform took that provider from the cache server. The lock file next to the unit still pins the hashes. A unit without a lock file does not use the cache.

The default cache directory is under your home directory. This lecture passes `--provider-cache-dir` so the cache sits next to the lab, where the checker can see it. `TG_PROVIDER_CACHE=1` and `TG_PROVIDER_CACHE_DIR` are the same two switches.

## The workflow stub

Apply runs on a push to `main`, which is the commit a merge creates. It does not run on `pull_request`.

| Setting | Value |
| --- | --- |
| `on` | `push` to `main` |
| `if` | `github.event_name == 'push' && github.ref == 'refs/heads/main'` |
| permissions | `id-token: write`, `contents: read` |
| concurrency | group `apply-main`, `cancel-in-progress: false` |
| role | `${{ vars.AWS_APPLY_ROLE_ARN }}` via `aws-actions/configure-aws-credentials@v6.3.0` |
| region | `us-east-1` |
| session | `terragrunt-apply` |
| command | `./scripts/apply.sh` |

`cancel-in-progress: false` keeps a second merge from killing an apply that is already writing state. The role step is the cloud part. On your machine, with the local backend, skip that step and run `./scripts/apply.sh`.

Treat `start/` as the repository root. The workflow file is what that repository would commit at `.github/workflows/apply.yml`.

## Layout

```text
start/
  root.hcl
  modules/record/
  network/terragrunt.hcl          # note = "apply on merge"
  service/terragrunt.hcl          # reads the network name at apply time
  scripts/apply.sh
  .github/workflows/apply.yml
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`. The apply script also passes `--tf-path terraform`.
2. Leave the units and `root.hcl` as they are.
3. Replace `start/scripts/apply.sh` with the command above. Keep it executable. The script `cd`s to the lecture directory, creates `.provider-cache`, and runs Terragrunt.
4. Replace `start/.github/workflows/apply.yml` with the workflow in [`solution/.github/workflows/apply.yml`](solution/.github/workflows/apply.yml). The comment above the role step marks it as the cloud step.
5. From `start/`:

```bash
terragrunt --working-dir network run -- version
./scripts/apply.sh
terragrunt --working-dir network output -raw note
terragrunt --working-dir network output -raw name
terragrunt --working-dir service output -raw note
```

The version line is Terraform 1.17.x. The network note is `apply on merge`. The service note equals the network name (`net-<word>-<word>`), not `mock-network-name`. `report.json` has `"Cmd": "apply"` and `"Result": "succeeded"` for both units. The log includes `Terragrunt Cache server stopped`.

6. Destroy the queue:

```bash
terragrunt --non-interactive run --all -- destroy -input=false
```

Service is destroyed, then network.

7. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  10.4 apply on merge
AWS was not contacted. The apply used the local backend. The workflow's role step is the cloud part.
```

The checker applies, checks the cache and the outputs, destroys, and deletes `.provider-cache`, `state/`, and `report.json`. Those paths are gitignored.

The workflow checker needs `python3` and PyYAML. The apply itself needs Terragrunt and Terraform.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first apply downloads those providers into `.provider-cache`. You do not need AWS credentials for `./check.sh`.

## If apply stops early

- The cache directory stays empty and the log never says `Terragrunt Cache server stopped` when the cache server was configured for OpenTofu. Pass `--tf-path terraform`.
- `Installed ... (unauthenticated)` is the cache server handing the provider over. It is the normal line for this setup.
- Service's note is `mock-network-name` when apply was allowed to use mocks. Keep the allow list at `validate` and `plan`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when a unit drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

The finished units match `start/`. The script and the workflow are in `solution/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
