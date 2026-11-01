# 07.2 Stack file

Author a `terragrunt.stack.hcl` that names each unit and where that unit should be generated. No AWS account.

## Goal

From `start/live`, make this succeed:

```bash
terragrunt stack generate
terragrunt stack run -- plan
```

The stack file has one `unit` block and one `stack` block. Generate writes `.terragrunt-stack/edge/` and `.terragrunt-stack/platform/`, and the nested stack writes its own `.terragrunt-stack/record/`. `stack run plan` plans two units. Each plan is `3 to add`. `terragrunt run -- version` in a generated unit prints Terraform 1.17.x.

## `unit` and `stack`

Both blocks live in `terragrunt.stack.hcl`.

| Block | Generates | This lecture |
| --- | --- | --- |
| `unit` | A directory with `terragrunt.hcl` | `edge`, from `units/record` |
| `stack` | A directory with another `terragrunt.stack.hcl`, which Terragrunt then generates | `platform`, from `blueprints/platform` |

`source` is where the files are copied from. `path` is the directory under `.terragrunt-stack/`.

`stack generate` copies the nested stack file to `.terragrunt-stack/platform/terragrunt.stack.hcl` and only then generates that stack's units. A `../units/record` path written for `blueprints/platform` would be resolved from the generated directory, and the fetch would fail. The blueprint anchors the unit on `root.hcl`:

```hcl
source = "${dirname(find_in_parent_folders("root.hcl"))}/units/record"
```

Leave that line as it is.

## Layout

```text
start/
  root.hcl
  modules/record/
  units/record/terragrunt.hcl                  # finished
  blueprints/platform/terragrunt.stack.hcl     # finished nested stack
  live/terragrunt.stack.hcl                    # unit and stack blocks go here
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Read `units/record/terragrunt.hcl` and `blueprints/platform/terragrunt.stack.hcl`. Leave them. The record unit sets `prefix` to `rec` and `note` to `record unit`.
3. Replace the TODOs in `start/live/terragrunt.stack.hcl`:

```hcl
unit "edge" {
  source = "../units/record"
  path   = "edge"
}

stack "platform" {
  source = "../blueprints/platform"
  path   = "platform"
}
```

Paths are relative to `live/`.

4. From `start/live`:

```bash
terragrunt stack generate
find .terragrunt-stack -type f -name 'terragrunt.hcl' -o -name 'terragrunt.stack.hcl' | sort
terragrunt stack run -- plan
```

Generate writes three files that matter:

```text
.terragrunt-stack/edge/terragrunt.hcl
.terragrunt-stack/platform/terragrunt.stack.hcl
.terragrunt-stack/platform/.terragrunt-stack/record/terragrunt.hcl
```

`edge` is a unit. `platform` is a stack, and its generated `record` is a unit. The run plans `edge` and the nested `record`. Each plan is `Plan: 3 to add, 0 to change, 0 to destroy.` `note` is `record unit`.

5. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  07.2 stack file`.

The lock file in `units/record` is copied into each generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials. `.terragrunt-stack/` stays gitignored.

## If generate stops early

- `relative paths require a module with a pwd` on the nested unit means the blueprint source was changed to a `../` path. Put the `find_in_parent_folders("root.hcl")` source back.
- `source = "TODO"` means a block in `live/terragrunt.stack.hcl` still has the placeholder.
- One plan instead of two means the `stack "platform"` block is missing, so the nested unit was never generated.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the blocks are not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your stack file with [`solution/live/terragrunt.stack.hcl`](solution/live/terragrunt.stack.hcl). The unit, the blueprint, and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
