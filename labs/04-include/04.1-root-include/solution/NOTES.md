# 04.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  04.1 root include
```

`root.hcl` holds `terraform_binary` and two inputs. The unit includes it and adds `prefix` and `note`.

| Setting | Where it is set | Value the unit runs with |
| --- | --- | --- |
| `terraform_binary` | `root.hcl` | `terraform` |
| `course` | `root.hcl` only | `terragrunt-labs` |
| `note` | both; the unit wins | `from the unit` |
| `prefix` | the unit only | `lab` |

`terragrunt render` in `unit/` includes:

```hcl
terraform_binary = "terraform"
inputs = {
  course = "terragrunt-labs"
  note   = "from the unit"
  prefix = "lab"
}
```

What the checker shows:

1. `terragrunt hcl fmt --check` passes for `root.hcl` and the unit.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>`. The unit file has no `terraform_binary` assignment. The include merges the one in `root.hcl`.
3. The plan is `3 to add`.
4. Apply output includes `course = "terragrunt-labs"`, `prefix = "lab"`, `note = "from the unit"`, and `name = "lab-<word>-<word>"`. The words change on every apply.
5. Destroy removes the three resources.

Commenting out the unit's `note` and rendering again shows `note = "from root"`. The checker expects the override to be in place.
