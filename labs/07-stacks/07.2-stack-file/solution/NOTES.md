# 07.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.2 stack file
```

`live/terragrunt.stack.hcl` has `unit "edge"` (`source = "../units/record"`, `path = "edge"`) and `stack "platform"` (`source = "../blueprints/platform"`, `path = "platform"`).

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. `terragrunt stack generate` writes `.terragrunt-stack/edge/terragrunt.hcl`, `.terragrunt-stack/platform/terragrunt.stack.hcl`, and `.terragrunt-stack/platform/.terragrunt-stack/record/terragrunt.hcl`.
3. `terragrunt stack run -- plan` plans two units, each `3 to add`, with note `record unit`.
4. Both the authored unit and the generated edge unit print Terraform 1.17.x.

The nested unit source stays anchored on `find_in_parent_folders("root.hcl")`. The module matches `start/`.
