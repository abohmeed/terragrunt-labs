# 02.3 CLI basics

Practice `run`, the OpenTofu shortcuts, and Terragrunt 1.x flags on a finished copy of the marker unit.

## Goal

From `start/`, run init, plan, apply, output, and destroy with Terragrunt 1.2. Use `--non-interactive`. Leave the old `--terragrunt-` prefix unused. No AWS account.

The unit in this directory is already complete, so you can practice the CLI without finishing 02.2 first. `terraform_binary = "terraform"` keeps the engine on Terraform 1.17.

## Commands

Run these from `start/`. `terragrunt run plan` and `terragrunt plan` both plan this unit. `plan` is a shortcut for `run`.

```bash
terragrunt run -- version
terragrunt run -- init
terragrunt run plan
terragrunt run -- plan -input=false
terragrunt plan -input=false
```

Terraform flags on the `run` command go after `--`. This is rejected, because `-input` is a Terraform flag:

```bash
terragrunt run plan -input=false
```

The 0.x flag name is rejected too:

```bash
terragrunt --terragrunt-non-interactive plan
```

The 1.x flag is `--non-interactive` (environment variable `TG_NON_INTERACTIVE=true`). It answers Terragrunt's own prompts. A single-unit `apply` still waits for Terraform's `yes` unless you pass `-auto-approve`:

```bash
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
```

Terragrunt copied the module into `.terragrunt-cache/` before Terraform ran. Find that working copy:

```bash
find .terragrunt-cache -name main.tf
find .terragrunt-cache -name marker.txt
```

`workspace` is not a shortcut. Terragrunt keeps state apart by unit, and the 1.x CLI will not forward that command unless you ask `run`:

```bash
terragrunt workspace list
terragrunt run -- workspace list
```

Destroy with the same flags:

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

## Check your run

`start/exercises.sh` runs the sequence above and exits non-zero if a command does something unexpected. It deletes `.terragrunt-cache` first, so the run starts cold:

```bash
./exercises.sh
```

The last line is `PASS  02.3 exercises`.

What you should have seen is written up in [`solution/NOTES.md`](solution/NOTES.md). `solution/` has the same unit and the same script.
