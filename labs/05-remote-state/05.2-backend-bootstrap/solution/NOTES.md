# 05.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  05.2 backend bootstrap
AWS was not contacted. Follow the README to bootstrap the bucket when you have credentials.
```

The checker does not call AWS. It does not run `backend bootstrap`, `plan`, or `apply`.

`root.hcl` holds `terraform_binary` and the S3 `remote_state` block.

| Setting | Value in the finished file |
| --- | --- |
| `backend` | `s3` |
| `bucket` | `example-terragrunt-labs-state` until you replace it |
| `key` | `${path_relative_to_include()}/terraform.tfstate` |
| `region` | `us-east-1` |
| `encrypt` | `true` |
| `use_lockfile` | `true` |
| `dynamodb_table` | unset |

`terragrunt render` in `dev/` includes `key = "dev/terraform.tfstate"`. Prod renders `key = "prod/terraform.tfstate"`. `terragrunt render --format json` includes `"use_lockfile":true` and `"encrypt":true` as booleans.

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>` and does not contact AWS.
3. Both renders show the S3 backend, the bucket, the per-unit key, the region, `encrypt = true`, and `use_lockfile = true`.
4. `terragrunt hcl validate --inputs --strict --tf-path terraform` reports that every variable is set.

With credentials, `terragrunt backend bootstrap` from a unit creates the bucket if it is missing and turns on versioning, server-side encryption, Block Public Access, and a TLS-only bucket policy. It does not create a DynamoDB table. Apply then writes `dev/terraform.tfstate` and `prod/terraform.tfstate`. The lock object is `<key>.tflock` and is removed when the operation finishes.

`terragrunt backend delete` removes the state object for the unit you run it in. Delete the bucket yourself after both units are destroyed. Versioning is on, so empty the bucket, including versions, before the bucket delete.
