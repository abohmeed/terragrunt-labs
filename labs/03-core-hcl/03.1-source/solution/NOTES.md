# 03.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  03.1 source
```

What the run is showing:

1. `terragrunt run -- version` prints `Terraform v1.17.<patch>`. `terraform_binary = "terraform"` selects that binary when `tofu` is also on `PATH`.
2. `terraform.source` is `${get_terragrunt_dir()}//modules/service`. Terragrunt copies the directory of `terragrunt.hcl`, then runs Terraform in `modules/service` inside that copy.
3. `modules/service/main.tf` sets `source = "../label"`. That path is a Terraform module source, relative to the staged `modules/service` directory. It resolves because `modules/label` was inside the copied tree.
4. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` The three resources are `module.label.random_pet.name`, `module.label.null_resource.marker`, and `module.label.local_file.marker`.
5. Terraform's working directory is `.terragrunt-cache/<hash>/<hash>/modules/service` (the folder that contains `.terraform`). `../label/main.tf` beside it is the child module. A source of `./modules/service` (no `//`) copies `modules/service` only, and init stops with `Unreadable module directory` for `../label`.
6. `terragrunt hcl validate --inputs --strict --tf-path terraform` reports that every module variable is set and that every input is declared. `--tf-path terraform` is required. Without it, `hcl validate --inputs` runs `tofu` even when the unit sets `terraform_binary`.
7. Apply prints `name = "lab-<word>-<word>"`. The words change on every apply. Destroy removes the three resources.

`start/` and `solution/` share the label module, the lock file, and `check.sh`. The edits are the two `source` lines.
