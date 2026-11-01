# 03.2 Locals and inputs

`locals` are values the unit computes. `inputs` are the values Terraform receives, and each key becomes a variable in the root module. Two units share one module and change the values. No AWS account.

## Goal

From `start/dev` and from `start/prod`, make this succeed:

```bash
terragrunt run plan
```

Each plan adds three resources. `dev` uses the prefix `dev-lab`. `prod` uses `prod-lab`. The module under `start/modules/record` stays the same for both.

## How a value moves

| Local | Input | Variable |
| --- | --- | --- |
| `local.environment` | `inputs.environment` | `var.environment` |
| `local.prefix` | `inputs.prefix` | `var.prefix` |
| `local.note` | `inputs.note` | `var.note` |

`prefix` is derived. Set `environment` and `prefix_root`, and leave this expression as it is:

```hcl
prefix = "${local.environment}-${local.prefix_root}"
```

Terraform does not read `locals`. A local reaches the module only when an input passes it.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. In `start/dev/terragrunt.hcl`, set `environment` to `dev` and `prefix_root` to `lab`.
3. Pass the three locals through `inputs`:

```hcl
inputs = {
  environment = local.environment
  prefix      = local.prefix
  note        = local.note
}
```

4. Repeat that in `start/prod/terragrunt.hcl` with `environment` set to `prod`. Keep `prefix_root` as `lab` and keep the same `note`.
5. From `start/dev`, then from `start/prod`:

```bash
terragrunt run plan
terragrunt run -- version
```

Each plan should end with `Plan: 3 to add, 0 to change, 0 to destroy.` The dev pet prefix is `dev-lab`. The prod pet prefix is `prod-lab`. The version line is Terraform 1.17.x.

The module writes `marker.txt` inside Terragrunt's working copy, not next to `terragrunt.hcl`. Each unit has its own `.terragrunt-cache` and its own state. The lock file next to each `terragrunt.hcl` pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan in a unit downloads those providers. You do not need AWS credentials.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  03.2 locals and inputs`. The script plans, applies, and destroys both units.

## If plan stops early

- Terraform asks for `var.environment` (or `prefix`, or `note`) when that input is missing. Press Ctrl-C and add the input. Filling `locals` alone leaves the variable empty from Terraform's side.
- An input name that the module does not declare fails `terragrunt hcl validate --inputs --strict --tf-path terraform`. Lecture 03.5 covers that command. The checker runs it for you.
- `source = "../modules/record"` is already set. The module is one directory up from `dev/` and from `prod/`.

Compare your units with [`solution/dev/terragrunt.hcl`](solution/dev/terragrunt.hcl) and [`solution/prod/terragrunt.hcl`](solution/prod/terragrunt.hcl). The module matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
