# OpenTofu and Terraform

## What stays the same

The unit, the inputs, and the local backend stay the same. `local`, `null`, and `random` still create the record. Terragrunt still reads `terragrunt.hcl`.

## .tofu files

OpenTofu loads `engine.tofu` and ignores `engine.tf` when both share the basename `engine`. Terraform ignores `.tofu` files and loads `engine.tf`. The output `engine_file` is `tofu` on OpenTofu and `tf` on Terraform. This is whole-file precedence, not a partial override.

## State encryption

OpenTofu can encrypt state and plan files with an `encryption` block or the `TF_ENCRYPTION` environment variable. Terraform has no equivalent block. It relies on backend encryption, such as S3 server-side encryption. This lab does not enable encryption. A key checked into the repository would be a leaked secret, and encrypted state cannot be read without that key.

## Versions and the binary

This section pins OpenTofu 1.13.x. The rest of the course pins Terraform 1.17.x. The numbers diverged after the fork, so OpenTofu 1.13 is not Terraform 1.13. `--tf-path` and `TG_TF_PATH` override `terraform_binary`.

OpenTofu records providers from `registry.opentofu.org`. A lock file that started on `registry.terraform.io` is rewritten, and the Terraform hashes are dropped, because the provider builds are not byte-for-byte identical. This section commits the OpenTofu lock file. Terraform then reports an inconsistent dependency lock file if it is asked to apply with that lock.
