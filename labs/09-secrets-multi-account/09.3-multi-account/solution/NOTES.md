# 09.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  09.3 multi-account
AWS was not contacted. Follow the README to bootstrap each account when you have credentials.
```

The checker does not call AWS. It does not run `backend bootstrap`, `plan`, or `apply`.

The live tree is `<account>/us-east-1/record`. Dev and prod are accounts, not environments inside one account. The two `terragrunt.hcl` files match. `account.hcl` is what changes.

| | Dev unit | Prod unit |
| --- | --- | --- |
| `account_name` | `dev` | `prod` |
| `account_id` | `111111111111` until you replace it | `222222222222` until you replace it |
| `role_arn` | `arn:aws:iam::111111111111:role/terragrunt-labs` | `arn:aws:iam::222222222222:role/terragrunt-labs` |
| `state_bucket` | `example-terragrunt-labs-dev-state` | `example-terragrunt-labs-prod-state` |
| `aws_region` | `us-east-1` | `us-east-1` |
| state key | `dev/us-east-1/record/terraform.tfstate` | `prod/us-east-1/record/terraform.tfstate` |
| `unit_path` | `dev/us-east-1/record` | `prod/us-east-1/record` |

`iam_role = local.role_arn` assumes that account's role for the whole run, including backend bootstrap and the S3 backend. `remote_state` leaves `role_arn` unset so the backend does not assume the same role again. The generated provider sets `region` and leaves `assume_role` unset for the same reason.

`encrypt` and `use_lockfile` render as the booleans `true`. `dynamodb_table` stays unset.

`terraform_binary` is set in `root.hcl` and merged by `include "root"`. `terragrunt run -- version` prints `Terraform v1.17.<patch>` in both units and does not assume a role.

The module is `modules/record` next to `root.hcl`. It still creates local, null, and random resources. `versions.tf` also requires `hashicorp/aws` `~> 6.0`. Each unit lock pins AWS provider 6.71.0, local 2.9.1, null 3.3.2, and random 3.9.1.

With credentials, `terragrunt backend bootstrap` from a unit creates that account's bucket if it is missing. Apply writes the state object at the key above. The lock object is `<key>.tflock`.
