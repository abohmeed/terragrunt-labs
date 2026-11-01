# 05.3 Terragrunt and workspaces

Run the same dev and prod data twice. Once as two Terragrunt directories with the local backend from lecture 05.1. Once as one Terraform configuration that uses workspaces. No AWS account.

## Goal

From the lecture directory, make `./check.sh` pass.

The layout writes:

```text
layout/state/dev/terraform.tfstate
layout/state/prod/terraform.tfstate
```

`terragrunt run -- workspace show` in either unit prints `default`.

The workspace configuration writes:

```text
workspaces/terraform.tfstate.d/dev/terraform.tfstate
workspaces/terraform.tfstate.d/prod/terraform.tfstate
```

`terraform workspace show` prints the name you selected. Apply in the `default` workspace fails.

## Two ways to split state

| | Directory per environment | Terraform workspaces |
| --- | --- | --- |
| Where you select | The directory you run in | `terraform workspace select` |
| State path | The `remote_state` path, one file per unit | `terraform.tfstate.d/<name>/terraform.tfstate` next to the configuration |
| Current selection | The directory is the whole selection | A name stored in `.terraform/environment`, and `default` when that file is absent |
| Code | Each directory has its own `terragrunt.hcl` | One `main.tf` for every environment |
| This course | Units stay on this pattern | Recognize the layout. Keep Terragrunt units on the `default` workspace |

Lecture 02.3 showed that `workspace` is not a Terragrunt shortcut. `terragrunt run -- workspace show` forwards the Terraform command. In a unit that uses `remote_state`, that command prints `default`, because the directory already separates the state.

The `path` in `workspaces/versions.tf` is the file Terraform would use for the `default` workspace. Named workspaces do not use that file. They use `terraform.tfstate.d` in the working directory. The precondition on `null_resource.marker` rejects `default` so an apply without `workspace select` stops.

## Layout

```text
start/
  layout/                      # lecture 05.1, copied so this lecture stands alone
    root.hcl
    modules/record/
    dev/terragrunt.hcl
    prod/terragrunt.hcl
  workspaces/                  # plain Terraform
    versions.tf                # local backend
    main.tf                    # environment comes from terraform.workspace
    outputs.tf
```

Leave `layout/` as it is. The edit is in `workspaces/main.tf`.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). The layout units inherit `terraform_binary = "terraform"` from `layout/root.hcl`.
2. Read `layout/root.hcl`. The state path is the one you wrote in lecture 05.1.
3. In `start/workspaces/main.tf`, set the environment from the selected workspace:

```hcl
locals {
  environment = terraform.workspace
  note        = "terraform workspace"
}
```

Leave the `lifecycle` precondition in place. It rejects the `default` workspace.

4. From `start/layout/dev`, then from `start/layout/prod`:

```bash
terragrunt run -- version
terragrunt run -- workspace show
terragrunt render
terragrunt run plan
```

The version line is Terraform 1.17.x. Workspace show prints `default`. Dev render shows `environment = "dev"`, `prefix = "dev-lab"`, and `note = "directory per environment"`. Prod shows `environment = "prod"` and `prefix = "prod-lab"`. Each plan is `Plan: 3 to add, 0 to change, 0 to destroy.` State files land under `layout/state/`.

5. From `start/workspaces`:

```bash
terraform init -input=false
terraform apply -auto-approve -input=false
terraform workspace new dev
terraform apply -auto-approve -input=false
terraform workspace new prod
terraform apply -auto-approve -input=false
terraform workspace show
terraform output
```

The first apply fails with `Create a named workspace before apply`. After the two named applies, `workspace show` prints `prod`, `environment` is `prod`, and `note` is `terraform workspace`. `terraform workspace select dev` then shows the dev outputs. The state files are `terraform.tfstate.d/dev/terraform.tfstate` and `terraform.tfstate.d/prod/terraform.tfstate`.

The lock files pin `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first init or plan in each tree downloads those providers. You do not need AWS credentials.

6. Destroy the workspaces, then the layout units:

```bash
terraform workspace select prod
terraform destroy -auto-approve -input=false
terraform workspace select dev
terraform destroy -auto-approve -input=false
terraform workspace select default
terraform workspace delete prod
terraform workspace delete dev
```

From each layout unit:

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  05.3 terragrunt and workspaces`. The script runs both trees, checks the state paths, and destroys them.

## If plan stops early

- `environment = "TODO"` means `workspaces/main.tf` still needs `terraform.workspace`.
- `environment = "dev"` in that file makes the prod workspace report `dev`. Read `terraform.workspace`.
- `Error: Resource precondition failed` on the first workspace apply means you are still on `default`. Run `terraform workspace new dev` before apply.
- `OpenTofu` from `terragrunt run -- version` in a layout unit means `terraform_binary` did not merge from `layout/root.hcl`.
- A layout state file under `layout/dev/` or `layout/prod/`, or a `terraform.tfstate.d` directory next to a unit, means the `remote_state` path from 05.1 was changed. Units keep the `default` workspace and split state by directory.
- `hcl fmt --check` fails on the Terragrunt files. `terraform fmt -check` fails on `workspaces/`. From `start/`, run `terragrunt hcl fmt` and `terraform fmt -recursive workspaces`, then run the checker again.

Compare your workspace file with [`solution/workspaces/main.tf`](solution/workspaces/main.tf). The layout matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
