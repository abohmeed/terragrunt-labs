# 07.6 Scaffold

Stamp a new unit or stack from a catalog entry with `terragrunt catalog` and `terragrunt scaffold`. No AWS account. This lecture uses the local catalog from lecture 07.5.

## Goal

From `start/`, make `./check.sh` pass.

`live/` is a scaffold of the catalog unit. Fill `live/terragrunt.values.hcl`, then `terragrunt run plan` in `live/` adds three resources. `note` is `scaffolded unit` and the generated `name` looks like `lab-smart-cattle`.

`stamped/` is a scaffold of the catalog stack. Fill its values, then `terragrunt stack run -- plan` plans one unit with prefix `stk`.

## `scaffold` writes different files for each kind

`terragrunt scaffold` takes a component source. The catalog's `component_source` uses `//`. From `start/`:

| Source | Kind | What scaffold writes |
| --- | --- | --- |
| `./catalog/modules/record` | Module | A new `terragrunt.hcl` that points `terraform.source` at the module and lists its variables |
| `./catalog//units/record` | Unit | A copy of the unit, plus `terragrunt.values.hcl` for every `values.*` reference |
| `./catalog//stacks/platform` | Stack | A copy of the stack, plus `terragrunt.values.hcl` for every `values.*` reference |

Pass `--non-interactive` so scaffold writes placeholders instead of opening a form. Pass `--root-file-name root.hcl` so a module scaffold includes this course's root file. Pass `--output-folder` to choose the directory. Scaffold refuses to overwrite a file that is already there.

A module scaffold leaves required inputs as `"" # TODO: fill in value`. A unit or stack that reads `values.environment` gets:

```hcl
# === Required ===
environment = "TODO"
prefix      = "TODO"

# === Optional (defaults from try() fallbacks) ===
note = "catalog note"
```

Required names are the ones the file reads directly. Optional names are the ones wrapped in `try(...)`, filled with that fallback. `--var` does not apply to a unit or a stack. It only fills a boilerplate template. Set unit and stack values in `terragrunt.values.hcl`.

A local path has no release tags. Scaffold warns that it failed to parse the URL and failed to find a last release tag, then still writes the files. The warning is expected in this lecture. The command exits 0.

`live/` and `stamped/` in this lecture are already the scaffold output, with the TODOs still in the values files. You can regenerate them into an empty directory and compare.

## Layout

```text
start/
  root.hcl                              # catalog block. Finished.
  catalog/modules/record/               # module
  catalog/units/record/                 # unit. Reads values.*
  catalog/stacks/platform/              # stack. Passes values.* into the unit
  live/                                 # scaffold of the unit. Fill the values.
  stamped/                              # scaffold of the stack. Fill the values.
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. List the catalog. `terragrunt catalog` reads `urls` from `root.hcl` when you pass `--root-file-name root.hcl`. A local path has to be a Git repository before that command will open it. Initialize it, list the entries, then remove the nested repository:

```bash
git init catalog
terragrunt catalog --format=jsonl --root-file-name root.hcl
rm -rf catalog/.git
```

Three lines. Kinds are `module`, `unit`, and `stack`. Passing the catalog path as an argument lists that repository without the `catalog` block: `terragrunt catalog --format=jsonl ./catalog` after the same `git init`.

3. Scaffold the module into an empty directory. This file is not something you keep. The checker scaffolds it again.

```bash
mkdir -p scratch-module
terragrunt --non-interactive scaffold --root-file-name root.hcl --output-folder scratch-module ./catalog/modules/record
```

`scratch-module/terragrunt.hcl` includes `root.hcl` and sets `environment = "" # TODO: fill in value`. Remove `scratch-module/` when you have read it. Do not scaffold the module on top of `live/`. `live/` is the unit, not the module.

4. The unit scaffold is already in `live/`. To regenerate it yourself, use an empty directory:

```bash
mkdir -p scratch-unit
terragrunt --non-interactive scaffold --root-file-name root.hcl --output-folder scratch-unit ./catalog//units/record
diff -u scratch-unit/terragrunt.hcl live/terragrunt.hcl
```

The `terragrunt.hcl` files match. `scratch-unit/terragrunt.values.hcl` still has `"TODO"`. `live/terragrunt.values.hcl` is the file you fill. Replace it with:

```hcl
environment = "dev"
prefix      = "lab"
note        = "scaffolded unit"
```

The comments scaffold wrote can stay. `hcl fmt` will align the equals signs.

5. From `start/live`:

```bash
terragrunt run -- version
terragrunt run plan
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output -raw name
terragrunt output -raw note
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

The version line is Terraform 1.17.x. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` `note` is `scaffolded unit`. `name` is `lab-<word>-<word>`.

6. Fill `start/stamped/terragrunt.values.hcl`. The stack scaffold is already there. Set:

```hcl
environment = "dev"
prefix      = "stk"
note        = "stack note"
```

`note` is the `try()` fallback. Leave it, or set it again. `prefix` has to be `stk`.

From `start/stamped`:

```bash
terragrunt stack generate
terragrunt stack run -- plan
```

The plan is one unit, `3 to add`, with prefix `stk`. Generate resolved `values.prefix` into `.terragrunt-stack/record/terragrunt.values.hcl`.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  07.6 scaffold`. The checker scaffolds the module, the unit, and the stack into temporary directories, diffs the copied `terragrunt.hcl` and `terragrunt.stack.hcl` against `live/` and `stamped/`, applies the live unit, and plans the stamped stack.

The lock file in the catalog unit is copied by scaffold and again by `stack generate`. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If scaffold or plan stops early

- `Failed to parse url` and `Failed to find last release tag` on a local path are the warnings from step 3. The files are still written when the command exits 0.
- Scaffold stops without writing when the output folder already contains a file it would create. Use an empty `--output-folder`, or edit the values file that is already in `live/` or `stamped/`.
- `values.environment` is unknown, or the value is still `"TODO"`, when the required lines were not replaced.
- `live/terragrunt.hcl` fails the diff when it was edited by hand. Put the scaffold copy back. Only `terragrunt.values.hcl` is yours to fill.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the values are not aligned. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

The filled values are in [`solution/live/terragrunt.values.hcl`](solution/live/terragrunt.values.hcl) and [`solution/stamped/terragrunt.values.hcl`](solution/stamped/terragrunt.values.hcl). The catalog matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
