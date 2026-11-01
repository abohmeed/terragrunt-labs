# 03.5 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  03.5 fmt, validate, and render
```

`start/terragrunt.hcl` is the same unit as `solution/terragrunt.hcl`, before `hcl fmt`. The formatter indents the blocks and aligns `=`.

`terragrunt render` resolves locals. The inputs block looks like this (key order can differ):

```hcl
inputs = {
  environment = "dev"
  note        = "rendered offline"
  prefix      = "lab"
}
```

The rendered file has no `local.` references. `terragrunt render --format json` includes `"environment":"dev"` and `"note":"rendered offline"`.

What the checker shows:

1. `terragrunt hcl fmt --diff` rewrites `start/terragrunt.hcl` on a fresh checkout. On `solution/`, the diff is empty. `hcl fmt --check` then exits 0.
2. `terragrunt hcl validate` parses the HCL.
3. `terragrunt hcl validate --inputs --strict --tf-path terraform` reports that every variable is set and that every input is declared. The debug log for this command runs `terraform -version`. The same command without `--tf-path` runs `tofu -version`, because `terraform_binary` does not apply to `hcl validate`.
4. Render output contains `environment = "dev"`, `prefix = "lab"`, and `note = "rendered offline"`.
5. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
6. The plan is `3 to add`. Apply output includes `environment = "dev"`, `note = "rendered offline"`, and `name = "lab-<word>-<word>"`. Destroy removes the three resources.

`hcl fmt` from this directory formats HCL here. It does not walk up into other lectures, and it does not format `.tf` files.
