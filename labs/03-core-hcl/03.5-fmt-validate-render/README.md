# 03.5 fmt, validate, and render

Format the unit, validate it, and render the configuration Terragrunt will run. The unit is already wired to a local module. No AWS account.

## Goal

From `start/`, format `terragrunt.hcl`, prove the inputs match the module, and read the rendered values. `./check.sh` ends with `PASS  03.5 fmt, validate, and render`.

`start/terragrunt.hcl` is valid and unformatted. `locals` hold `environment`, `prefix`, and `note`. `inputs` passes those locals to `modules/record`. `terraform_binary = "terraform"` keeps `terragrunt run` on Terraform 1.17 when `tofu` is on `PATH`.

## Steps

Run these from `start/`.

`hcl fmt` rewrites `*.hcl` under this directory into canonical form. `fmt` and `format` are the same command. It leaves `.tf` files alone. See the diff, then format:

```bash
terragrunt hcl fmt --diff
terragrunt hcl fmt
terragrunt hcl fmt --check
```

`--diff` prints the change and writes it. `--check` exits 0 when every file is already formatted, and exits 1 when a file would change. Run it from this directory. It does not walk up into other lectures.

Validate the HCL, then validate inputs against the module:

```bash
terragrunt hcl validate
terragrunt hcl validate --inputs --strict --tf-path terraform
```

`hcl validate` parses the files. `hcl validate --inputs` checks that every required variable is set. `--strict` also rejects an input the module does not declare.

`hcl validate --inputs` runs `tofu -version` unless you pass `--tf-path`. `terraform_binary` in the unit does not change this command. `--tf-path terraform` selects Terraform 1.17. `terragrunt run` still follows `terraform_binary`.

Render the unit. Locals and function calls are already resolved, so you can read the values Terraform will receive:

```bash
terragrunt render
terragrunt render --format json
```

`inputs` in the HCL render shows `"dev"`, `"lab"`, and `"rendered offline"` rather than `local.environment`, `local.prefix`, and `local.note`. `--format json` prints the same result as one JSON object. `--json` is the same flag.

`--write` saves `terragrunt.rendered.hcl` (or `.json`) next to the unit. This lab reads stdout. If you try `--write`, delete that file before you commit. It is not part of the lab.

Confirm the engine and the plan:

```bash
terragrunt run -- version
terragrunt run plan
```

The version line is Terraform 1.17.x. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

Run the checker. It formats, validates, renders, plans, applies, and destroys. The cache is removed at the start, so the run is cold:

```bash
./check.sh
```

The last line is `PASS  03.5 fmt, validate, and render`.

`start/.terraform.lock.hcl` pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If a command stops early

- `hcl fmt` fails to parse a file when a block opens and closes on different lines after a one-line argument. Put each argument on its own line, then format again.
- `hcl validate --inputs` without `--tf-path terraform` reports OpenTofu. Pass `--tf-path terraform`.
- An extra input fails `--strict` with `inputs that are not defined in the OpenTofu/Terraform module`. Remove the extra key.
- A missing input fails with a message that a required variable is not set. Add the input.

After `hcl fmt`, `start/terragrunt.hcl` matches [`solution/terragrunt.hcl`](solution/terragrunt.hcl). The module matches `solution/` as well. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
