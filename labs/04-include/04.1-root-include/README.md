# 04.1 Root include

Move shared settings into `root.hcl` and pull that file into a unit with an `include` block. No AWS account.

## Goal

From `start/unit`, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. `course` is `terragrunt-labs` from `root.hcl`. `prefix` is `lab` and `note` is `from the unit`, both set by the unit. `terragrunt run -- version` prints Terraform 1.17.x. The unit file does not set `terraform_binary`.

## Layout

```text
start/
  root.hcl            # terraform_binary and shared inputs
  unit/
    terragrunt.hcl
    modules/record/
```

`root.hcl` is a parent. Terragrunt runs a directory as a unit only when that directory contains `terragrunt.hcl`.

`include` merges the parent into the unit:

| In `root.hcl` | What the unit receives |
| --- | --- |
| `terraform_binary = "terraform"` | The same setting, used by `terragrunt run` |
| `inputs.course` | `course = "terragrunt-labs"`, because the unit leaves `course` unset |
| `inputs.note` | The unit value `from the unit`, because the unit sets `note` too |

This is the default merge, `shallow`. Each top-level `inputs` key from the root stays when the unit leaves that key unset. A key set in both files keeps the unit value. Nested maps are lecture 04.2.

Parent `locals` stay in the parent. Lecture 03.3 reads them with `read_terragrunt_config`. Lecture 04.3 reads them by exposing the include.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Read `start/root.hcl`. Leave it as it is.
3. Replace the TODOs in `start/unit/terragrunt.hcl`. The include and the inputs are:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  prefix = "lab"
  note   = "from the unit"
}
```

Leave `course` out of the unit. Keep `terraform.source` pointed at `./modules/record`.

4. From `start/unit`:

```bash
terragrunt run -- version
terragrunt render
terragrunt run plan
```

The version line is Terraform 1.17.x. The render shows `terraform_binary = "terraform"`, `course = "terragrunt-labs"`, `prefix = "lab"`, and `note = "from the unit"`. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

5. Comment out `note` in the unit and run `terragrunt render` again. The render shows `note = "from root"`. Put `note = "from the unit"` back before you continue. The checker expects the unit value.

6. Apply, read the outputs, and destroy:

```bash
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

`course` is `terragrunt-labs`. `note` is `from the unit`. `name` is `lab-<word>-<word>`.

The lock file next to the unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  04.1 root include`.

## If plan stops early

- `find_in_parent_folders("TODO")` means the include path still needs `root.hcl`.
- Terraform asks for `var.course` when the include is missing, so the root inputs never merge. Press Ctrl-C and fix the include.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge. It belongs in `root.hcl`, and the unit includes that file.
- A `note` of `from root` means the unit's `inputs.note` is missing. Put `from the unit` back.
- `hcl fmt --check` fails when the alignment differs from the snippet above. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl). `root.hcl` and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
