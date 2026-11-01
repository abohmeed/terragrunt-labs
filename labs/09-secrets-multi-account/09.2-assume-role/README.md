# 09.2 Assume role ☁️

Assume one IAM role from a unit, and generate the AWS provider stub that uses that session.

This lecture needs an AWS account for plan and apply. `./check.sh` does not call AWS. It checks the configuration and renders the unit on your machine. Run the checker before you spend time on credentials.

## Goal

`start/root.hcl` assumes a role and generates `provider.tf`:

| Setting | Value |
| --- | --- |
| `account_id` | A 12-digit account id. The file ships with `111111111111`. Replace that before plan |
| `role_arn` | `arn:aws:iam::${local.account_id}:role/terragrunt-labs` |
| `iam_role` | `local.role_arn` |
| `generate "provider"` | Writes `provider.tf` with `if_exists = "overwrite_terragrunt"` |
| provider stub | `provider "aws"` with `region = local.aws_region` |

`iam_role` is what assumes the role. Terragrunt calls `sts:AssumeRole` and exports the session before it runs Terraform. The generated provider sets the region and uses that session.

Leave `assume_role` out of the provider stub. A second assume of `terragrunt-labs`, using credentials that are already that role, is denied. AWS does not allow a role to assume itself.

The resources in the unit stay on the `local`, `null`, and `random` providers. The AWS provider is initialized so the session is real. This lecture does not create AWS resources, and state stays on your machine. Lecture 09.3 puts state in a bucket per account.

## Layout

```text
start/
  root.hcl                 # terraform_binary, iam_role, provider stub
  modules/record/
  unit/terragrunt.hcl      # include and inputs
  unit/.terraform.lock.hcl
```

## Offline steps

Do these before you use AWS. They are what `./check.sh` runs.

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Replace the TODOs in `start/root.hcl`. Keep the `locals` block that is already there, and add:

```hcl
iam_role = local.role_arn

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
  EOF
}
```

`111111111111` is a placeholder so the render has a legal account id. The checker accepts any 12-digit id. Put your account id in `account_id` before the AWS steps below. `role_arn` is built from that local, so you change the id in one place. Leave the role name `terragrunt-labs`.

3. From `start/unit`:

```bash
terragrunt run -- version
terragrunt render
terragrunt render --format json
```

The version line is Terraform 1.17.x. Version does not assume the role. The render shows `iam_role = "arn:aws:iam::111111111111:role/terragrunt-labs"` (or your account id) and a generated provider whose region is `us-east-1`. The JSON form has `"iam_role"` set to that ARN.

4. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  09.2 assume role
AWS was not contacted. Follow the README to create the role when you have an account.
```

The script formats the HCL, checks the block, and renders the unit. It does not run `plan` or `apply`. It sets `AWS_EC2_METADATA_DISABLED` so a missing credential cannot sit on the instance metadata service.

## AWS steps

Use a sandbox account. Keep credentials in the environment (`AWS_PROFILE`, or `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`). Do not commit them.

You need two identities:

- The caller. This is the user or role already in your environment. `aws sts get-caller-identity` prints its ARN.
- The role `terragrunt-labs` in the account where this unit runs. Terragrunt assumes it.

1. Create the role `terragrunt-labs`. Its trust policy must name the caller. For an IAM user, the principal is the user ARN. For a role you are already in, use that role's ARN, not the `assumed-role/.../session` ARN from the caller identity.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::CALLER_ACCOUNT:user/YOUR_USER"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

2. The caller needs `sts:AssumeRole` on `arn:aws:iam::ACCOUNT:role/terragrunt-labs`. The role itself does not need an extra policy for this lecture. Provider init calls `sts:GetCallerIdentity`, which a role can do without an attached policy. The unit creates no buckets and no other AWS resources.
3. Put your account id in `account_id`. From `start/`, `./check.sh` still passes.
4. From `start/unit`:

```bash
terragrunt run -- version
terragrunt run plan
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
```

Plan assumes `terragrunt-labs`, initializes the AWS provider with that session, and adds three local resources. Apply output has `environment = "dev"`, `prefix = "assume"`, and `note = "assume role"`. The pet name changes on every apply.

The lock file pins `aws` 6.71.0, `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. `modules/record/versions.tf` is the only `required_providers` block. Terraform 1.17 rejects a second one, so the generated file is only the provider stub.

5. Destroy the unit. State is local to `unit/`:

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

Leave the role in place if you are continuing to lecture 09.3. Otherwise delete `terragrunt-labs`.

## If plan stops early

- `no EC2 IMDS role found`, or a timeout talking to `169.254.169.254`, means the shell has no AWS credentials. Export a profile or keys for the caller, then run the command again.
- `AccessDenied` on `AssumeRole` means the trust policy does not name the caller, or the caller is missing `sts:AssumeRole` on the role.
- `is not authorized to perform: sts:AssumeRole` on `role/terragrunt-labs` while the caller is already `terragrunt-labs` means the provider stub also contains `assume_role`. Remove that block. `iam_role` already assumed the role.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- The checker fails on `iam_role` missing, on `assume_role` in `root.hcl`, and on an account id that is not 12 digits.
- `hcl fmt --check` fails when the alignment differs from the snippet above. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your root file with [`solution/root.hcl`](solution/root.hcl). The unit and the module match `start/`. What the checker prints, and what plan assumes, is written up in [`solution/NOTES.md`](solution/NOTES.md).
