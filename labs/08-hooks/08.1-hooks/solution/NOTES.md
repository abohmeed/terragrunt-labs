# 08.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  08.1 hooks
```

The three hooks are inside the unit's `terraform` block. `root.hcl` still holds `terraform_binary = "terraform"`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. `terragrunt run -- version` prints Terraform 1.17.x.
3. The successful plan is `3 to add` with note `hooks lab`. The log contains `before hook: plan starts` and `after hook: plan finished`, and does not contain `error hook: plan failed`.
4. `terragrunt run -- plan -var note=fail` exits non-zero. Terraform prints `deliberate plan failure`. The before hook runs, the error hook runs, and the after hook does not, because `run_on_error` is false.

The words in a pet name change on every apply. This lecture plans and does not apply. The module matches `start/`.
