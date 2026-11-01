# 12.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  12.1 switch to OpenTofu
```

`root.hcl` sets `terraform_binary = "tofu"`. The lock file selects `registry.opentofu.org`.

What the checker shows:

1. `tofu version` is OpenTofu 1.13.x. `terragrunt --version` is 1.2.x.
2. `scripts/engines.sh` prints OpenTofu 1.13.x for the attribute, and Terraform 1.17.x for `--tf-path terraform` and for `TG_TF_PATH=terraform`.
3. Apply writes note `switched to tofu`. Destroy removes the unit.
