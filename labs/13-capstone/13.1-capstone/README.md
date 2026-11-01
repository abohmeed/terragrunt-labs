# 13.1 Capstone

Build a dev and prod stack from the local catalog, plan and apply it with a CI-shaped script, and leave the AWS role step commented. No AWS account. The role step is the ☁️ part, and it stays a stub.

## Goal

From `start/`, make `./check.sh` pass.

The catalog is finished. Each live environment has two units, `network` and `service`, both generated from `catalog/units/record`. Service's note becomes the network name at apply time. The plan uses the mock. `scripts/plan.sh` and `scripts/apply.sh` run both environments on the local backend. The workflow files show where the OIDC step from lecture 10.2 would go, and they do not call AWS.

## The catalog source

`terragrunt catalog` lists a module, a unit, and a stack when `catalog/` is a Git repository. A local directory needs `git init` first. It does not need a commit. The checker copies the lecture, runs `git init` in the copy's `catalog/`, and deletes the copy.

The live stack uses the `//` form:

```hcl
source = "../../catalog//units/record"
```

That path does not need the `git init`. `stack run` generates `.terragrunt-stack/network` and `.terragrunt-stack/service`.

| Environment | Network prefix | Network note | Service prefix |
| --- | --- | --- | --- |
| dev | `dev` | `dev network` | `svc` |
| prod | `prd` | `prod network` | `svc` |

Service's `values.note` is replaced at apply time by `dependency.network.outputs.name`. Mocks are allowed for `validate` and `plan`. A cold plan shows `mock-network-name`. Apply runs network first, so service stores the real name, `dev-<word>-<word>` or `prd-<word>-<word>`.

State uses the local backend from lecture 05.1:

```text
state/${path_relative_to_include()}/terraform.tfstate
```

## The CI-shaped flow

A pull request plans. A push to `main` applies. That is the shape from lectures 10.3 and 10.4. On your machine the scripts are the commands those jobs would run. `--tf-path terraform` keeps the run on Terraform 1.17 when `tofu` is on `PATH`.

The role step is commented in both workflow files. Uncommenting it is lecture 10.2, and it needs an AWS account. `./check.sh` does not uncomment it and does not call AWS.

| File | Trigger | Command | Cloud step |
| --- | --- | --- | --- |
| `.github/workflows/plan.yml` | `pull_request` | `./scripts/plan.sh` | commented `AWS_PLAN_ROLE_ARN` |
| `.github/workflows/apply.yml` | `push` to `main` | `./scripts/apply.sh` | commented `AWS_APPLY_ROLE_ARN` |

Apply uses `cancel-in-progress: false` so a second merge does not kill an apply that is already writing state. Plan may cancel an older plan of the same pull request.

## Layout

```text
start/
  root.hcl                              # catalog block and local backend. Finished.
  catalog/modules/record/
  catalog/units/record/                 # finished
  catalog/stacks/env/                   # finished. Listed by terragrunt catalog.
  live/dev/terragrunt.stack.hcl         # source goes here
  live/prod/terragrunt.stack.hcl
  scripts/plan.sh
  scripts/apply.sh
  .github/workflows/plan.yml
  .github/workflows/apply.yml
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Replace both TODO sources with:

```hcl
source = "../../catalog//units/record"
```

Keep the `values` blocks and the `autoinclude`. Dev and prod use the same source.
3. Replace `start/scripts/plan.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for env in dev prod; do
  terragrunt --no-color --non-interactive --working-dir "live/${env}" \
    stack run --tf-path terraform -- plan -input=false -no-color
done
```

4. Replace `start/scripts/apply.sh` with the same loop, and `apply` instead of `plan`. Keep both scripts executable.
5. Replace the workflow stubs with [`solution/.github/workflows/plan.yml`](solution/.github/workflows/plan.yml) and [`solution/.github/workflows/apply.yml`](solution/.github/workflows/apply.yml). Leave the role steps commented.
6. From `start/`:

```bash
./scripts/plan.sh
./scripts/apply.sh
terragrunt --working-dir live/dev stack output --format json --tf-path terraform
terragrunt --working-dir live/prod stack output --format json --tf-path terraform
```

The plan is four times `3 to add`. Each service plan uses `mock-network-name`. After apply, each service note equals that environment's network name, and the network notes are `dev network` and `prod network`.

7. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  13.1 capstone
AWS was not contacted. The apply used the local backend. The workflow role steps stay commented.
```

The checker plans, applies, checks both stacks, destroys, and deletes `state/`. The lock file in `catalog/units/record` is copied into each generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If plan or apply stops early

- `source = "TODO"` means a live stack still has the placeholder. Use `../../catalog//units/record`, including the two slashes.
- Service's note is `mock-network-name` after apply when `apply` was added to `mock_outputs_allowed_terraform_commands`. Keep that list at `validate` and `plan`.
- `OpenTofu v` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`, or `--tf-path terraform` was left off the script.
- `is not a git repository` from `terragrunt catalog` means `catalog/` was not initialized. The checker initializes a copy. Remove `catalog/.git` if you initialized the lecture itself.
- An active `role-to-assume` line fails the checker. The role ARN stays in a comment.
- `hcl fmt --check` fails when a stack file drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

The catalog matches `start/`. The stack sources, scripts, and workflows are in `solution/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
