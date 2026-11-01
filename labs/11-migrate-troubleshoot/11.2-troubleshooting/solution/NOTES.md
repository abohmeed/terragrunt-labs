# 11.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  11.2 troubleshooting
```

`live/` contains `terragrunt.stack.hcl` only. `units/record/terragrunt.hcl` is the unit. The local note is `traced from render`.

What the checker shows:

1. A temporary directory that contains both `terragrunt.hcl` and `terragrunt.stack.hcl` fails with `A component must be either a unit or a stack, not both.`
2. `scripts/debug.sh` passes `--log-level debug` and `--tf-path terraform`. The log includes `DEBUG` and `Running command: terraform -version`.
3. `render --format json` resolves `note` to `traced from render`.
4. The generated unit prints Terraform 1.17.x. The plan is `3 to add`.
