# 03.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  03.3 functions
```

The unit is `dev/unit`. Parents are resolved from that directory:

| File | Found from the unit | Value the unit reads |
| --- | --- | --- |
| `dev/env.hcl` | `find_in_parent_folders("env.hcl")` | `environment = "dev"`, `prefix_root = "lab"` |
| `region.hcl` | `find_in_parent_folders("region.hcl")` | `region = "local"` |
| `root.hcl` | `find_in_parent_folders("root.hcl")` | `course = "terragrunt-labs"` |

`path_relative_to_include("root")` is `dev/unit`.

`prefix` is `dev-local-lab` (`environment`, `region`, and `prefix_root` joined with `-`).

What the checker shows:

1. `terragrunt hcl fmt --check` passes for `root.hcl`, `region.hcl`, `dev/env.hcl`, and the unit.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
3. With `LAB_NOTE` unset, apply output is:

```text
course = "terragrunt-labs"
environment = "dev"
name = "dev-local-lab-<word>-<word>"
note = "offline functions lab"
prefix = "dev-local-lab"
region = "local"
unit_path = "dev/unit"
```

4. With `LAB_NOTE="from the environment"`, `note` is `from the environment`. The other outputs stay the same. The words in `name` change on every apply.
5. Destroy runs after each apply. The script deletes `.terragrunt-cache` before the second apply so the second run is cold.

`include "root"` is the anchor for `path_relative_to_include`. Parent locals are read with `read_terragrunt_config(...).locals`, because include does not copy `locals` into the child.
