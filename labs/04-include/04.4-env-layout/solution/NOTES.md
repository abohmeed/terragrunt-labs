# 04.4 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  04.4 environment layout
```

The live tree is `sandbox/local/<env>/record`: account, region, environment, unit. `local` stands in for a cloud region.

`dev/record/terragrunt.hcl` and `prod/record/terragrunt.hcl` are the same file. `find_in_parent_folders("env.hcl")` resolves `dev/env.hcl` from the dev unit and `prod/env.hcl` from the prod unit.

| | Dev unit | Prod unit |
| --- | --- | --- |
| `course` | `terragrunt-labs` | `terragrunt-labs` |
| `account` | `sandbox` | `sandbox` |
| `region` | `local` | `local` |
| `environment` | `dev` | `prod` |
| `prefix` | `sandbox-dev-lab` | `sandbox-prod-lab` |
| `unit_path` | `sandbox/local/dev/record` | `sandbox/local/prod/record` |

`prefix` joins `account`, `environment`, and `prefix_root` from `env.hcl`. `prefix_root` stays a local. It is not an input.

The module is `modules/record` next to `root.hcl`. `terraform.source` is `${dirname(find_in_parent_folders("root.hcl"))}/modules/record`, so the dev and prod copies both find it.

What the checker shows:

1. `terragrunt hcl fmt --check` passes for every `.hcl` file under the lecture directory.
2. The two unit files are byte-for-byte the same.
3. `terragrunt run -- version` prints `Terraform v1.17.<patch>` in both units. `terraform_binary` is set in `root.hcl` and merged by `include "root"`.
4. Each plan is `3 to add`. Apply output includes `name = "<prefix>-<word>-<word>"`. The words change on every apply.
5. Destroy removes that unit's three resources. The other unit has its own cache and is unaffected.

`account`, `region`, and `env` are exposed with `merge_strategy = "no_merge"`. The unit reads `include.<label>.locals`.
