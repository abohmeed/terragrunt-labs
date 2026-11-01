# 03.1 Source

A Terragrunt unit and a Terraform module each have a `source`. This lab runs a local root module that calls a second local module. No AWS account.

## Goal

From `start/`, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. State stays under `.terragrunt-cache/`, which git ignores.

## Two sources

`modules/service` is the root module the unit runs. `modules/label` creates the pet name, the null marker, and `marker.txt`. The root module calls it from `modules/service/main.tf`:

```hcl
module "label" {
  source = "../label"

  prefix = var.prefix
  note   = var.note
}
```

`source` here is a Terraform module source. The path is relative to `modules/service`. Terraform resolves it after Terragrunt has copied the module tree into `.terragrunt-cache`.

`start/terragrunt.hcl` chooses what gets copied. It currently says:

```hcl
terraform {
  source = "./modules/service"
}
```

A path without `//` copies that directory only. `modules/label` stays on disk beside the unit, and `../label` is missing from the working copy.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). From the repo root, `mise install`, then activate mise so `terragrunt` and `terraform` are on `PATH`.
2. In `start/modules/service/main.tf`, set the module source to `../label`.
3. From `start/`, run:

```bash
terragrunt run plan
```

Init stops here. The error names `../label` (`Unreadable module directory`). The unit copied `modules/service` and left `modules/label` behind.

4. In `start/terragrunt.hcl`, set the unit source to:

```hcl
source = "${get_terragrunt_dir()}//modules/service"
```

The `//` is Terragrunt syntax. The directory before `//` is copied into `.terragrunt-cache`. The path after `//` is the root module inside that copy. `get_terragrunt_dir()` is the directory of this `terragrunt.hcl`, so the copy includes both `modules/service` and `modules/label`.

5. Plan again. It should end with `Plan: 3 to add, 0 to change, 0 to destroy.`

6. Confirm the staged copy, and confirm the engine:

```bash
find .terragrunt-cache -type d -name .terraform
terragrunt run -- version
```

The `.terraform` directory sits in the staged `modules/service` folder. `../label/main.tf` next to that folder is the module Terraform called. The first line of the version command is Terraform 1.17.x. `terraform_binary = "terraform"` selects that binary. With `tofu` on `PATH` and no `terraform_binary`, Terragrunt 1.2 runs OpenTofu instead.

`start/.terraform.lock.hcl` pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers from the Terraform registry. Later plans reuse the download. You do not need AWS credentials.

7. When both sources are in place, run:

```bash
./check.sh
```

The last line is `PASS  03.1 source`. The script plans, checks the staged copy, applies, and destroys.

## If plan stops early

- `source = "../TODO"` means the module source in `modules/service/main.tf` still needs `../label`.
- `Unable to evaluate directory symlink: lstat ../label` means the unit source copied `modules/service` only. Use the `//` form.
- A missing `prefix` makes Terraform wait for `var.prefix`. Press Ctrl-C. This unit already sets `inputs.prefix`.

Compare your unit with [`solution/terragrunt.hcl`](solution/terragrunt.hcl) and [`solution/modules/service/main.tf`](solution/modules/service/main.tf). The label module matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
