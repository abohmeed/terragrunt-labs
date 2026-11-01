# 08.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  08.2 lint hooks
```

`.mise.toml` pins `tflint = "0.65.0"`. The binary is not in this repo. The checker installs that release when `tflint` is missing, and skips the live plan only if the install fails. `.tflint.hcl` uses the ruleset shipped inside that binary and does not declare a `plugin` block.

`hooks/checkov` execs Checkov when the binary is on `PATH`. Otherwise it rejects `allow_all` in a `.tf` file. The checker forces that stand-in for the `allow_all` case.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x. The tflint pin is `0.65.0`.
2. The unit has `before_hook` blocks named `tflint`, `fmt`, and `checkov`. `terraform_binary` stays in `root.hcl`.
3. The stand-in fails a file that contains `allow_all` and accepts `modules/record`.
4. When tflint 0.65.x is available, the plan is `3 to add` with note `lint hooks`. The log contains `Tflint has run successfully. No issues found.` and both later hooks run. `terragrunt run -- version` prints Terraform 1.17.x.

The words in a pet name change on every apply. This lecture plans and does not apply. The module matches `start/`.
