# 04.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  04.3 multiple includes
```

The unit includes three parents. `expose = true` on each one. `region` and `env` use `merge_strategy = "no_merge"`. `root` uses the default shallow merge, so `terraform_binary` is inherited.

| Value | Expression | Result |
| --- | --- | --- |
| `course` | `include.root.locals.course` | `terragrunt-labs` |
| `region` | `include.region.locals.region` | `local` |
| `environment` | `include.env.locals.environment` | `dev` |
| `prefix` | environment, region, and `include.env.locals.prefix_root` | `dev-local-lab` |
| `unit_path` | `path_relative_to_include("root")` | `dev/unit` |
| `note` | set in the unit | `exposed includes` |

What the checker shows:

1. `terragrunt hcl fmt --check` passes for `root.hcl`, `region.hcl`, `dev/env.hcl`, and the unit.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>`. The unit file has no `terraform_binary` assignment.
3. The plan is `3 to add`.
4. Apply output includes `course = "terragrunt-labs"`, `region = "local"`, `environment = "dev"`, `prefix = "dev-local-lab"`, `unit_path = "dev/unit"`, `note = "exposed includes"`, and `name = "dev-local-lab-<word>-<word>"`. The words change on every apply.
5. Destroy removes the three resources.

Parent `locals` are read through `include.<label>.locals`. Include does not copy `locals` into the child.
