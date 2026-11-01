# 07.4 Stack generate

Generate the stack into `.terragrunt-stack` and run the generated units. That directory stays gitignored. No AWS account.

## Goal

From `start/live`, the stack file is already written. This lecture is the commands. Make `./check.sh` pass.

`terragrunt stack generate` writes `.terragrunt-stack/network` and `.terragrunt-stack/service`. `terragrunt stack run` generates again, then runs every generated unit. `terragrunt stack output` prints both units. `terragrunt stack clean` deletes `.terragrunt-stack/`.

## Commands

Run these from the directory that contains `terragrunt.stack.hcl`. Terraform arguments stay after `--`.

| Command | What it does |
| --- | --- |
| `terragrunt stack generate` | Writes `.terragrunt-stack/` from `terragrunt.stack.hcl` |
| `terragrunt stack run -- plan` | Generates, then plans every generated unit |
| `terragrunt stack run -- apply` | Generates, then applies. Adds `-auto-approve` |
| `terragrunt stack run -- destroy` | Generates, then destroys, dependencies last. Adds `-auto-approve` |
| `terragrunt stack output` | Prints every unit output. This is not `stack run output` |
| `terragrunt stack clean` | Deletes `.terragrunt-stack/` |
| `terragrunt stack run --no-stack-generate -- plan` | Runs what is already generated and does not write the stack again |

`stack run` generates on its own. Use `stack generate` when you want to read the files before a run. Pass `--no-stack-generate` when you want a run to leave the generated files alone. With nothing generated, that run reports `No units discovered`.

`stack run` discovers every unit under the working directory, not only the units the stack file generated. The record unit reads `values`, and that object exists only after generate writes `terragrunt.values.hcl`. Run from `live/`. The source unit is `../units/record`, outside that directory, so the queue is the two generated units.

The repo gitignore already has `.terragrunt-stack/` and `**/.terragrunt-stack/`. Generate does not create a commit.

State for this lecture is inside `.terragrunt-stack/`. `stack clean` deletes it. Destroy before you clean. A remote backend, as in lecture 05, is how a stack keeps state when the generated directory is removed. This lecture does not set one.

## Layout

```text
start/
  root.hcl                         # terraform_binary. Not a unit.
  modules/record/
  units/record/                    # source unit. No terragrunt.values.hcl here.
  live/terragrunt.stack.hcl        # the stack. This directory has no terragrunt.hcl.
```

`root.hcl` is not `terragrunt.hcl`, so a directory can hold both `root.hcl` and a stack file. `terragrunt.hcl` and `terragrunt.stack.hcl` cannot share a directory. This lecture keeps the stack in `live/` so the source unit stays outside the run.

The service unit depends on network through an `autoinclude`, the same shape as lecture 07.3. A cold plan uses `mock-network-name`. Apply runs network first, and the service `note` becomes the network `name`.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. From `start/live`:

```bash
terragrunt stack generate
find .terragrunt-stack -type f | sort
git check-ignore -v .terragrunt-stack
```

Network and service each get `terragrunt.hcl` and `terragrunt.values.hcl`. Service also gets `terragrunt.autoinclude.hcl`. `git check-ignore` prints the gitignore rule for `.terragrunt-stack`.

3. Still in `start/live`, plan, apply, and read the stack output:

```bash
terragrunt --non-interactive stack run -- plan -input=false
terragrunt --non-interactive stack run -- apply -input=false
terragrunt stack output
terragrunt --working-dir .terragrunt-stack/network run -- version
```

The plan queue names network, then service. Each plan is `3 to add`. The cold service `note` is `mock-network-name`. After apply, service `note` equals the network `name`, a value like `net-smart-cattle`. The version line is Terraform 1.17.x.

4. Still in `start/live`, destroy, clean, and try a run that does not generate:

```bash
terragrunt --non-interactive stack run -- destroy -input=false
terragrunt stack clean
terragrunt --non-interactive stack run --no-stack-generate -- plan -input=false
```

`stack clean` removes `.terragrunt-stack/`. The last command reports `No units discovered` and does not recreate the directory.

5. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  07.4 stack generate`.

The lock file in `units/record` is copied into each generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If the run stops early

- `No units discovered` before you have generated, and without `--no-stack-generate`, means `terragrunt.stack.hcl` is not in the working directory. Run from `start/live`.
- `There is no variable named "values"` on `units/record` means `stack run` was started from `start/` and discovered the source unit. Run from `start/live`.
- `detected no outputs` on plan means the service mock was removed. `plan` has to be allowed to use `mock_outputs` while network has never been applied.
- `git check-ignore` prints nothing when it is run outside this repository. The pattern lives in the repo `.gitignore`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.

The finished stack matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
