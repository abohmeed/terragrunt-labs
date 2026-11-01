# 07.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.1 units vs stacks
```

`units/record` is a unit: one `terragrunt.hcl`, one Terraform run, no include of `_envcommon`. `stack/` is a stack: `terragrunt.stack.hcl` names that unit. `terragrunt run plan` in `stack/` fails because that directory has no `terragrunt.hcl`. `terragrunt stack generate` writes `.terragrunt-stack/record/`.

`legacy/dev` and `legacy/prod` still include `_envcommon/record.hcl`. `terragrunt find` does not list `_envcommon`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. The stack unit source is `../units/record` and the path is `record`.
3. Legacy dev plans `3 to add` with note `legacy include`.
4. `units/record` plans `3 to add` with note `one unit`. `terragrunt run -- version` prints Terraform 1.17.x.
5. `stack generate` writes the unit. The generated unit plans `3 to add` on Terraform 1.17.x.
6. `terragrunt find` lists `units/record` and `stack`, and does not list `_envcommon`.

The words in a pet name change on every apply. This lecture plans and does not apply. The module matches `start/`.
