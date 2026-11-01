# 04.2 Merge

Choose how an included file combines with the unit: `shallow`, `deep`, or `no_merge`. The three units below include the same `root.hcl` and set the same kind of override. The strategy is what changes the result. No AWS account.

## Goal

From `start/`, make `./check.sh` pass. Each unit plans three resources. `terragrunt render` in each unit matches the table below.

## The three strategies

`merge_strategy` is an argument of `include`. Omitting it selects `shallow`, which is what lecture 04.1 used.

| Strategy | Scalars | Maps | Lists |
| --- | --- | --- | --- |
| `shallow` | The unit value wins | The unit map replaces the root map | The unit list replaces the root list |
| `deep` | The unit value wins | Keys merge. The unit wins on a shared key | The root items, then the unit items |
| `no_merge` | The root value is not applied | The root map is not applied | The root list is not applied |

`no_merge` still parses the parent when `expose = true`. The unit reads `include.root.inputs` and copies the keys it wants. Nothing else from the parent is applied, including `terraform_binary`.

## Layout

```text
start/
  root.hcl
  modules/record/
  shallow/terragrunt.hcl
  deep/terragrunt.hcl
  no_merge/terragrunt.hcl
```

`root.hcl` is a parent. It sets `terraform_binary` and these inputs:

```hcl
inputs = {
  course = "terragrunt-labs"
  note   = "from root"
  tags = {
    owner       = "platform"
    tier        = "shared"
    cost_center = "labs"
  }
  labels = ["course", "shared"]
}
```

Each unit overrides `note`, replaces `tags` with a one-key map, and replaces `labels` with a one-item list. `course` stays on the root, except in `no_merge`, where the unit copies it.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1).
2. Read `start/root.hcl`. Leave it as it is.
3. In `start/shallow/terragrunt.hcl`, set the include to:

```hcl
include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "shallow"
}
```

Leave `terraform_binary` unset in this unit. The shallow include inherits it. Keep the `inputs` block that is already there.

4. In `start/deep/terragrunt.hcl`, use the same include with `merge_strategy = "deep"`. Leave `terraform_binary` unset here too.

5. In `start/no_merge/terragrunt.hcl`, expose the root and skip the merge. `no_merge` does not inherit `terraform_binary`, so the unit sets it:

```hcl
include "root" {
  path           = find_in_parent_folders("root.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform_binary = "terraform"

inputs = {
  course = include.root.inputs.course
  prefix = "no-merge"
  note   = "from the unit"
  tags = {
    tier = "app"
  }
  labels = ["unit"]
}
```

`include.root.inputs.course` is the exposed root value. The other root inputs stay out of this unit on purpose.

6. From each unit directory, render:

```bash
terragrunt render
```

| Key | `shallow` | `deep` | `no_merge` |
| --- | --- | --- | --- |
| `course` | `terragrunt-labs` | `terragrunt-labs` | `terragrunt-labs` (copied through `expose`) |
| `note` | `from the unit` | `from the unit` | `from the unit` |
| `prefix` | `shallow` | `deep` | `no-merge` |
| `tags` | `tier = "app"` only | `owner`, `tier = "app"`, `cost_center` | `tier = "app"` only |
| `labels` | `["unit"]` | `["course", "shared", "unit"]` | `["unit"]` |

7. From `start/shallow`, confirm the engine, then repeat in `deep/` and `no_merge/`:

```bash
terragrunt run -- version
terragrunt run plan
```

The version line is Terraform 1.17.x in all three. Removing `terraform_binary` from `no_merge/` makes that unit print OpenTofu, because `tofu` is on `PATH` and the root value was not merged. Put the line back.

Each plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan in a unit downloads those providers. You do not need AWS credentials.

8. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  04.2 merge`. The script renders, plans, applies, and destroys all three units.

## If plan stops early

- `Invalid merge strategy` means `merge_strategy` is still `TODO` or some other word. Use `shallow`, `deep`, or `no_merge`.
- `include.root` is unknown when `expose = true` is missing on the `no_merge` include.
- Terraform asks for `var.course` in `no_merge/` when `course` is still `"TODO"`. Set it from `include.root.inputs.course`.
- `OpenTofu` in `no_merge/` means that unit is missing `terraform_binary = "terraform"`.
- A deep render without `owner` means that unit is still using `shallow`. `shallow` replaces the whole `tags` map.
- `hcl fmt --check` fails when the include arguments are not aligned. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your units with [`solution/shallow/terragrunt.hcl`](solution/shallow/terragrunt.hcl), [`solution/deep/terragrunt.hcl`](solution/deep/terragrunt.hcl), and [`solution/no_merge/terragrunt.hcl`](solution/no_merge/terragrunt.hcl). `root.hcl` and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
