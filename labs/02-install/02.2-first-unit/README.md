# 02.2 First unit

Run one Terragrunt unit that calls a local module. The module uses the `random`, `null`, and `local` providers. No AWS account and no remote backend.

## Goal

Finish `start/terragrunt.hcl` so this command succeeds from `start/`:

```bash
terragrunt run plan
```

The plan creates three resources and talks only to your machine. State stays under `.terragrunt-cache/`, which git already ignores.

## The module

`start/modules/marker/` is complete. Read it before editing the unit:

- `random_pet.name` builds a name from `var.prefix`.
- `null_resource.marker` records that name and `var.note`.
- `local_file.marker` writes them to `marker.txt` inside Terragrunt's working copy of the module, not next to `terragrunt.hcl`.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). From the repo root, `mise install`, then activate mise so `terragrunt` and `terraform` are on `PATH`.
2. In `start/terragrunt.hcl`, point `terraform.source` at `./modules/marker`.
3. Set `inputs.prefix` to a short string such as `lab`. Leave `note` as it is, or change the sentence.
4. From `start/`, run:

```bash
terragrunt run plan
```

The first plan downloads the three providers from the Terraform registry. Later plans reuse that download. You do not need AWS credentials.

5. Read the plan. It should end with `Plan: 3 to add, 0 to change, 0 to destroy.` The pet name and the file contents stay `(known after apply)`.

`start/.terraform.lock.hcl` pins the providers that init already selected: `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The `zh:` hashes in that file are valid on other operating systems. Terragrunt copies this lock file into the working directory on init.

`terraform_binary = "terraform"` is already set. Terragrunt 1.2 would otherwise run OpenTofu, because `mise install` puts `tofu` on `PATH`. Check the engine with:

```bash
terragrunt run -- version
```

The first line should be Terraform 1.17.x.

## If plan stops early

- `source = "./modules/TODO"` fails with `no such file or directory`. Point it at `./modules/marker`.
- A missing `prefix` makes Terraform ask `var.prefix` and wait for input. Press Ctrl-C and set `inputs.prefix`.

Apply and destroy are the next lecture. Compare your unit with [`solution/terragrunt.hcl`](solution/terragrunt.hcl) when you want the finished file. The module files match `start/`.
