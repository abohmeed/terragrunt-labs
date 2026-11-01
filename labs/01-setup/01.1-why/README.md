# 01.1 Why Terragrunt

Three copied Terraform roots are where plain Terraform starts to hurt. A Terragrunt 1.x **unit** is one deployable piece. A **stack** is a group of units. This lecture only reads files. Nothing is installed and nothing is applied.

## Goal

From `start/`, read the three copies and run:

```bash
./check.sh
```

The last line is `PASS  01.1 why Terragrunt`. The checker compares `dev`, `staging`, and `prod` on disk. It does not call Terraform, Terragrunt, or AWS.

Leave the drift in place. The copies are the demonstration.

## The copies

```text
start/
  dev/        main.tf  backend.tf  provider.tf  terraform.tfvars
  staging/    the same four files, copied
  prod/       the same four files, copied
  check.sh
```

`main.tf` stands in for a root that would hold a network, a database, and an app. It is the same file in every folder. `terraform.tfvars` is the only place the prefix changes, and it changes because each folder is its own root.

`backend.tf` uses the local backend so this lecture stays on your machine. The state path is still a hard-coded key. The backend block cannot take a variable, so the path is typed again in every copy. An S3 backend has the same limit: the bucket and the key are literals in every copy.

`provider.tf` is where the copies drifted. `dev` asks for Terraform 1.17 and `random` 3.6. `staging` still says Terraform 1.9 and `random` 3.5. `prod` still says Terraform 1.6 and `random` 3.4. A fourth environment would be a fourth copy of every file.

## Unit and stack

Terragrunt does not replace Terraform. It calls Terraform (or OpenTofu) after it prepares the working directory.

One deployable piece is a **unit**: a directory with a `terragrunt.hcl` file. The file points at a module, sets inputs, and that run gets its own state. [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl) is that shape. The module lives once, under [`solution/modules/record`](solution/modules/record). The environment folder no longer contains its own `main.tf`.

A group of units is a **stack**. In Terragrunt 1.x a stack can be described in `terragrunt.stack.hcl`, and Terragrunt generates the units. Section 07 builds that. [`solution/NOTES.md`](solution/NOTES.md) previews the file and ties it back to these copies.

Splitting one large root into units also shrinks the blast radius: one state file and one lock per unit. Terraform does not order those units. Terragrunt does, once a unit depends on another. That is section 06.

## Steps

1. Open `start/dev`, `start/staging`, and `start/prod`. Each folder is a full root: `main.tf`, `backend.tf`, `provider.tf`, and `terraform.tfvars`.
2. Diff `main.tf`. The resource block is the same file, copied.
3. Read each `backend.tf`. The path is a literal (`dev/terraform.tfstate`, then `staging`, then `prod`). There is no variable to share.
4. Read each `provider.tf`. Confirm `dev` is on Terraform 1.17 and `random` 3.6, and that the other two copies were not updated.
5. Read `terraform.tfvars`. The prefix differs. The module code does not, because the module was copied rather than shared.
6. Open [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl). `terraform.source` is `../modules/record`. `inputs` replaces the copied `terraform.tfvars`. `terraform_binary = "terraform"` is how later labs stay on Terraform when OpenTofu is also installed.
7. Read [`solution/NOTES.md`](solution/NOTES.md) for the path from these copies to a unit, then to a stack.
8. From `start/`, run `./check.sh`. From `solution/`, the same script checks the unit sketch and ends with `PASS  01.1 solution`.

Do not run `terraform init` here. Lecture 02.1 installs the CLIs. Lecture 02.2 runs the first unit.
