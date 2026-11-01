# 09.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  09.2 assume role
AWS was not contacted. Follow the README to create the role when you have an account.
```

The checker does not call AWS. It does not run `plan` or `apply`. `AWS_EC2_METADATA_DISABLED` is set so a missing credential fails immediately instead of waiting on the instance metadata service.

`root.hcl` holds `terraform_binary`, `iam_role`, and `generate "provider"`.

| Setting | Value in the finished file |
| --- | --- |
| `account_id` | `111111111111` until you replace it |
| `role_arn` | `arn:aws:iam::${local.account_id}:role/terragrunt-labs` |
| `iam_role` | `local.role_arn` |
| provider stub | `provider "aws"` with `region = local.aws_region` |
| `assume_role` | unset |

`iam_role` is the assume. Terragrunt calls `sts:AssumeRole`, then exports that session for Terraform. The generated `provider.tf` only sets the region, so the AWS provider uses the session Terragrunt already obtained. An `assume_role` block on that provider would assume `terragrunt-labs` a second time, and AWS denies a role assuming itself.

`terragrunt render` in `unit/` shows `iam_role = "arn:aws:iam::111111111111:role/terragrunt-labs"` and a `provider "aws"` stub whose region is `us-east-1`. `terragrunt run -- version` prints `Terraform v1.17.<patch>` and does not assume the role.

The module still creates the local, null, and random resources from earlier lectures. `versions.tf` also requires `hashicorp/aws` `~> 6.0`. The lock file pins AWS provider 6.71.0, local 2.9.1, null 3.3.2, and random 3.9.1. The first plan downloads those providers.

With credentials, plan assumes `terragrunt-labs`, initializes the AWS provider with that session, and adds the three local resources. State stays on this machine. Lecture 09.3 moves state into a bucket per account.
