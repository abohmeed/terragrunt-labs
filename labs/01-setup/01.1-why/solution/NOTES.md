# 01.1 completed notes

`check.sh` is the same script as `start/check.sh`. From `start/` a passing run ends with:

```text
PASS  01.1 why Terragrunt
```

From this directory the same script checks the unit sketch and ends with:

```text
PASS  01.1 solution
```

Nothing is initialized or applied. The CLIs are lecture 02.1. The first real unit run is lecture 02.2.

## What the copies show

`start/dev`, `start/staging`, and `start/prod` are three Terraform roots. `main.tf` is the same file in each folder. `terraform.tfvars` is edited per copy, which is how the prefix drifts away from the shared code.

| Copy | Backend path | Terraform | random provider |
| --- | --- | --- | --- |
| dev | `dev/terraform.tfstate` | `>= 1.17.0, < 1.18.0` | `~> 3.6` |
| staging | `staging/terraform.tfstate` | `>= 1.9.0, < 1.10.0` | `~> 3.5` |
| prod | `prod/terraform.tfstate` | `>= 1.6.0, < 1.7.0` | `~> 3.4` |

The backend block cannot use variables, so each copy hard-codes its state path. That path is the key for this copy. On an S3 backend the bucket and the key are hard-coded the same way. `dev` was moved to Terraform 1.17 and random 3.6. Staging and prod were not. That is provider version drift.

A fourth environment would be a fourth copy of `main.tf`, `backend.tf`, `provider.tf`, and `terraform.tfvars`.

One more limit sits under the copies. A single root module is one state file and one lock, so every plan touches every resource. Splitting that root into smaller pieces gives each piece its own state. Those pieces then have to run in order. Terraform does not do that orchestration.

## Unit

`unit/terragrunt.hcl` is one unit: a directory with a `terragrunt.hcl` file. `terraform.source` points at `../modules/record`. `inputs` sets `prefix` and `note` for this unit. The module stays in one place. The environment-specific values stay in the unit, so the next environment is another small `terragrunt.hcl`, not another copy of the module.

`terraform_binary = "terraform"` selects Terraform. Terragrunt 1.2 runs OpenTofu when `tofu` is on `PATH`. Later labs set the binary for that reason. This lecture does not install either CLI.

Each unit gets its own state. A shared backend block, written once and included by every unit, is section 04 and section 05. Ordering units that read each other's outputs is section 06.

## Stack preview

A stack is a group of units. In Terragrunt 1.x one file, `terragrunt.stack.hcl`, can generate the units:

```hcl
unit "record" {
  source = "../unit"
  path   = "record"
}
```

`source` is the unit directory. `path` is where Terragrunt writes the generated copy. Section 07 builds that file for real. [07.1 Units vs stacks](../../07-stacks/07.1-units-vs-stacks/) separates a unit (`terragrunt.hcl`) from a stack (`terragrunt.stack.hcl`). Nothing in this lecture generates a stack.
