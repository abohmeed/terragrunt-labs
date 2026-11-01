# 07.1 Units vs stacks

Separate a unit (one OpenTofu or Terraform run) from a stack (a generated set of units), and see why `_envcommon` goes away. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`units/record` is a unit. `terragrunt run plan` there is one Terraform run. `stack/` is a stack. It has `terragrunt.stack.hcl` and no `terragrunt.hcl`, so `terragrunt run plan` there fails. `terragrunt stack generate` writes that same unit under `stack/.terragrunt-stack/record/`.

`legacy/dev` and `legacy/prod` are the shape this lecture leaves behind. Both include `_envcommon/record.hcl`.

## Unit, stack, and `_envcommon`

| | What it is | File | What you run |
| --- | --- | --- | --- |
| Unit | One Terraform run | `terragrunt.hcl` | `terragrunt run plan` in that directory |
| Stack | A blueprint that generates units | `terragrunt.stack.hcl` | `terragrunt stack generate`, then run the generated units |
| `_envcommon` | A partial file from Terragrunt 0.x | `record.hcl`, not `terragrunt.hcl` | Nothing. Other units include it |

A directory cannot be both a unit and a stack. Terragrunt errors if it finds `terragrunt.hcl` and `terragrunt.stack.hcl` in the same directory.

In 0.x, the shared source lived in `_envcommon/record.hcl`. It was not a unit. Every environment kept its own `terragrunt.hcl` that included the partial and overrode inputs. That is `legacy/dev` and `legacy/prod`.

Stacks retire that partial. The shared configuration is a real unit, `units/record`. The stack names the unit and Terragrunt generates the copy. Nothing in the new path includes `_envcommon`. `terragrunt find` does not list it, because find lists units and stacks only.

## Layout

```text
start/
  root.hcl                         # terraform_binary
  modules/record/
  _envcommon/record.hcl            # the old partial. Leave it.
  legacy/dev/terragrunt.hcl        # includes _envcommon. Leave it.
  legacy/prod/terragrunt.hcl       # same include, different prefix. Leave it.
  units/record/terragrunt.hcl      # the unit that replaces _envcommon. Finished.
  stack/terragrunt.stack.hcl       # unit block goes here
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Read `_envcommon/record.hcl`, both legacy units, and `units/record/terragrunt.hcl`. Leave them. The record unit does not include `_envcommon`. Its `note` is `one unit`.
3. Replace the TODOs in `start/stack/terragrunt.stack.hcl`:

```hcl
unit "record" {
  source = "../units/record"
  path   = "record"
}
```

`source` is the unit directory, relative to the stack file. `path` is the directory Terragrunt generates under `.terragrunt-stack/`.

4. From `start/units/record`, then from `start/stack`:

```bash
terragrunt run -- version
terragrunt run plan
```

The unit version line is Terraform 1.17.x. The unit plan is `Plan: 3 to add, 0 to change, 0 to destroy.` and `note` is `one unit`. The stack command fails. Terragrunt says the folder does not contain a `terragrunt.hcl` file. That directory is not a unit.

5. Generate the stack and plan the generated unit:

```bash
cd ../stack
terragrunt stack generate
terragrunt --working-dir .terragrunt-stack/record run -- version
terragrunt --working-dir .terragrunt-stack/record run plan
```

Generate writes `.terragrunt-stack/record/terragrunt.hcl`. That file is a copy of the record unit. It does not include `_envcommon`. The plan is again `3 to add` with note `one unit`.

`.terragrunt-stack/` is gitignored. Lecture 07.4 is where you run the generated stack. This lecture only generates and plans.

6. From `start/legacy/dev`:

```bash
terragrunt run plan
```

The plan is `3 to add`. `note` is `legacy include`. Prod is the same include with prefix `oldprod`. You do not have to plan prod. The checker plans dev.

7. From `start/`:

```bash
terragrunt find
./check.sh
```

`find` lists `units/record`, `legacy/dev`, `legacy/prod`, and `stack`. It does not list `_envcommon`. The last line of the checker is `PASS  07.1 units vs stacks`.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If plan stops early

- `does not contain a terragrunt.hcl file` in `stack/` is the result this lecture is demonstrating. Generate the stack, and plan `.terragrunt-stack/record`.
- `source = "TODO"` means the stack unit still has the placeholder. Point it at `../units/record`.
- A generated unit that includes `_envcommon` means the record unit still includes the partial. The unit file is the replacement. Leave the include on the legacy units only.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the block is not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your stack file with [`solution/stack/terragrunt.stack.hcl`](solution/stack/terragrunt.stack.hcl). The unit, the legacy includes, and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
