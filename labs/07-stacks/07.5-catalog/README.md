# 07.5 Catalog

Pull a unit definition from a catalog so the stack file references a published entry. No AWS account. This lecture uses a local catalog, not a Git host.

## Goal

From `start/`, make `./check.sh` pass.

`terragrunt catalog --format=jsonl --root-file-name root.hcl` lists three entries: a module, a unit, and a stack. `live/terragrunt.stack.hcl` points its unit `source` at the catalog unit with the `//` form the catalog prints. `terragrunt stack run -- plan` plans that generated unit. The plan is `3 to add` and `note` is `catalog unit`.

## What a catalog is

A catalog is a repository of components Terragrunt can browse and stamp out. `terragrunt catalog` classifies every directory it finds:

| Kind | How Terragrunt recognizes it | In this lecture |
| --- | --- | --- |
| Module | OpenTofu or Terraform `.tf` files | `catalog/modules/record` |
| Unit | A directory with `terragrunt.hcl` | `catalog/units/record` |
| Stack | A directory with `terragrunt.stack.hcl` | `catalog/stacks/platform` |

`terragrunt find` does not list the module. The catalog does. The unit and the stack show up in both.

The `catalog` block in `root.hcl` names where to look. A URL can be a Git repository. A relative path is resolved from `root.hcl`. This lecture uses the local directory so nothing is cloned:

```hcl
catalog {
  urls = [
    "./catalog",
  ]
}
```

`terragrunt catalog` opens that path as a Git repository. A local directory needs `git init` before the command will read it. It does not need a commit or a remote. The checker copies the lecture, runs `git init` in the copy's `catalog/`, and deletes the copy. Do the same when you want to browse it yourself, and remove `catalog/.git` afterwards so this repo does not gain a nested repository.

The root file in this course is `root.hcl`, not `terragrunt.hcl`. Pass `--root-file-name root.hcl` or the command will not see the `catalog` block.

`--format=jsonl` prints one JSON object per line, which is what you want when stdout is not a terminal. `--format=md` prints the same entries as Markdown. With no `--format`, a terminal opens the catalog TUI and anything else gets jsonl.

Each object has a `component_source`. The separator is `//`:

```text
.../catalog//units/record
```

A stack uses that form as a `source`. From `live/`, the catalog unit is:

```hcl
source = "../catalog//units/record"
```

That is a local path. It does not need the `git init` the catalog command needs. `stack generate` copies the unit into `.terragrunt-stack/record/`.

## Layout

```text
start/
  root.hcl                              # catalog block goes here
  catalog/modules/record/               # module
  catalog/units/record/terragrunt.hcl   # unit. Finished.
  catalog/stacks/platform/              # stack. Finished.
  live/terragrunt.stack.hcl             # source goes here
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Add the `catalog` block above to `start/root.hcl`. Keep `terraform_binary = "terraform"`.
3. From `start/`, make a temporary Git repository and list the catalog:

```bash
tmp="$(mktemp -d)"
cp -a catalog "$tmp/catalog"
git -C "$tmp/catalog" init
terragrunt catalog --format=jsonl "$tmp/catalog"
rm -rf "$tmp"
```

You should see three JSON lines. `kind` is `module`, `unit`, and `stack`. `dir` is `modules/record`, `units/record`, and `stacks/platform`. `title` comes from each `README.md` heading: `Record`, `Record unit`, and `Platform`. `component_source` contains `//`.

The same list, using the block in `root.hcl`:

```bash
git init catalog
terragrunt catalog --format=jsonl --root-file-name root.hcl
rm -rf catalog/.git
```

4. Replace the TODO in `start/live/terragrunt.stack.hcl`:

```hcl
unit "record" {
  source = "../catalog//units/record"
  path   = "record"
}
```

5. From `start/live`:

```bash
terragrunt stack generate
terragrunt stack run -- plan
terragrunt --working-dir .terragrunt-stack/record run -- version
```

The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` `note` is `catalog unit`. The version line is Terraform 1.17.x.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  07.5 catalog`.

The lock file in `catalog/units/record` is copied into the generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If catalog or plan stops early

- `is not a git repository` means `terragrunt catalog` was pointed at `catalog/` before `git init`. Initialize a copy, or initialize `catalog/` and remove `catalog/.git` when you are done.
- An empty JSON stream, or a catalog that does not list these three entries, means the `catalog` block was not read. Pass `--root-file-name root.hcl`.
- `source = "TODO"` means the live stack still has the placeholder. Use `../catalog//units/record`, including the two slashes.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the block is not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your root file and stack file with [`solution/root.hcl`](solution/root.hcl) and [`solution/live/terragrunt.stack.hcl`](solution/live/terragrunt.stack.hcl). The catalog matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
