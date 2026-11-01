# 09.3 Multi-account ☁️

Run the same unit in two accounts. Each account has its own role, its own state bucket, and its own state key.

This lecture needs two AWS accounts for bootstrap, plan, and apply. `./check.sh` does not call AWS. It checks the configuration and renders both units on your machine. Run the checker before you spend time on credentials.

## Goal

Dev and prod are accounts. They include the same root and run the same unit file. `account.hcl` is what changes.

| Setting | Where it lives | Dev | Prod |
| --- | --- | --- | --- |
| `account_name` | `account.hcl` | `dev` | `prod` |
| `account_id` | `account.hcl` | `111111111111` until you replace it | `222222222222` until you replace it |
| `role_name` | `account.hcl` | `terragrunt-labs` | `terragrunt-labs` |
| `role_arn` | built in `account.hcl` | `arn:aws:iam::<dev account>:role/terragrunt-labs` | `arn:aws:iam::<prod account>:role/terragrunt-labs` |
| `state_bucket` | `account.hcl` | `example-terragrunt-labs-dev-state` until you replace it | a different bucket name |
| `aws_region` | `region.hcl` | `us-east-1` | `us-east-1` |
| state key | rendered | `dev/us-east-1/record/terraform.tfstate` | `prod/us-east-1/record/terraform.tfstate` |

`iam_role = local.role_arn` assumes that account's role for the whole run, including `backend bootstrap` and the S3 backend. Leave `role_arn` out of the `remote_state` config. Leave `assume_role` out of the generated provider. Both would assume `terragrunt-labs` a second time, and AWS denies a role assuming itself.

`use_lockfile` is the S3 lock from lecture 05.2. Leave `dynamodb_table` unset.

The resources in the unit stay on the `local`, `null`, and `random` providers. AWS is the identity and the state backend.

## Layout

```text
start/
  root.hcl                                  # terraform_binary
  modules/record/
  dev/
    account.hcl                             # dev account id, role, bucket
    us-east-1/
      region.hcl
      record/terragrunt.hcl                 # unit
  prod/
    account.hcl
    us-east-1/
      region.hcl
      record/terragrunt.hcl                 # same file as dev
```

`find_in_parent_folders("account.hcl")` stops at the account directory above the unit. Dev and prod each have their own file of that name.

The includes follow lecture 04.4. Merge `root`, because that file holds `terraform_binary`. Expose `account` and `region`, and set `merge_strategy = "no_merge"` on those two. They are data.

There are two includes with `expose = true`, not four. This tree has no `env.hcl`.

The module lives once, next to `root.hcl`:

```hcl
source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
```

## Offline steps

Do these before you use AWS. They are what `./check.sh` runs.

1. Install the pinned CLIs if you have not (lecture 02.1). The unit does not set `terraform_binary`. The root include merges it from `root.hcl`.
2. Read both `account.hcl` files and both `region.hcl` files. Leave the role name `terragrunt-labs` and the region `us-east-1`. The account ids and bucket names in the scaffold are placeholders. Replace them before the AWS steps. The checker accepts any 12-digit ids and any lowercase bucket names, as long as dev and prod differ.
3. Replace the TODOs in `start/dev/us-east-1/record/terragrunt.hcl`. Keep the three `include` blocks, the `terraform` block, and the `inputs` block. The locals, the role, the backend, and the provider stub are:

```hcl
locals {
  account_name = include.account.locals.account_name
  account_id   = include.account.locals.account_id
  role_arn     = include.account.locals.role_arn
  state_bucket = include.account.locals.state_bucket
  aws_region   = include.region.locals.aws_region
  unit_path    = path_relative_to_include("root")
}

iam_role = local.role_arn

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = local.state_bucket
    key          = "${path_relative_to_include("root")}/terraform.tfstate"
    region       = local.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

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

`path_relative_to_include("root")` needs the include label because this unit has more than one include. A call with no argument fails.

4. Copy that `terragrunt.hcl` over `start/prod/us-east-1/record/terragrunt.hcl`. The files stay identical. Prod reads `prod/account.hcl` because `find_in_parent_folders("account.hcl")` stops at the first parent with that name.

5. From the dev unit, then from the prod unit:

```bash
terragrunt run -- version
terragrunt render
terragrunt render --format json
```

The version line is Terraform 1.17.x. Version does not assume the role. Dev render shows account `111111111111` (or your dev id), bucket `example-terragrunt-labs-dev-state` (or your bucket), key `dev/us-east-1/record/terraform.tfstate`, and `iam_role` for the dev role. Prod shows the prod account, the prod bucket, and key `prod/us-east-1/record/terraform.tfstate`. The JSON form has `"encrypt":true` and `"use_lockfile":true` as booleans.

6. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  09.3 multi-account
AWS was not contacted. Follow the README to bootstrap each account when you have credentials.
```

The script formats the HCL, checks that the unit files match, and renders both units. It does not run `backend bootstrap`, `plan`, or `apply`.

## AWS steps

Use two sandbox accounts. One identity in a third account, or in one of these two, is the caller. That caller assumes `terragrunt-labs` in each target account. Keep the caller's credentials in the environment. Do not commit them.

1. In each target account, create the role `terragrunt-labs`. The trust policy names the caller, the same way lecture 09.2 did. Use the caller's IAM user ARN or role ARN, not an assumed-role session ARN.

The caller needs `sts:AssumeRole` on both role ARNs.

2. Each role needs to create and configure its own state bucket: versioning, encryption, Block Public Access, and the TLS bucket policy. It also needs to read and write objects in that bucket, including the `.tflock` object. Bootstrap calls `sts:GetCallerIdentity` as the role. The unit's resources are still local, so the role does not need permission to create EC2, IAM, or anything else.

`example-terragrunt-labs-dev-state` and `example-terragrunt-labs-prod-state` are placeholders. S3 bucket names are global. Put a name you own in each `state_bucket` before bootstrap. Put the real account id in each `account_id`. `role_arn` follows `account_id`.

3. From `start/`, `./check.sh` still passes after those edits.
4. From `start/dev/us-east-1/record`:

```bash
terragrunt --non-interactive backend bootstrap
terragrunt run -- version
terragrunt run plan
terragrunt --non-interactive run -- apply -auto-approve -input=false
```

`terragrunt --non-interactive run --backend-bootstrap -- apply -auto-approve -input=false` bootstraps and applies in one command.

Bootstrap runs as `terragrunt-labs` in the dev account, so the bucket is created in that account. Apply writes `dev/us-east-1/record/terraform.tfstate`. Dev output has `account_name = "dev"`, your dev account id, `aws_region = "us-east-1"`, `unit_path = "dev/us-east-1/record"`, and `note = "multi account"`.

5. From `start/prod/us-east-1/record`, run bootstrap and apply again. Prod uses the prod role and the prod bucket. The state key is `prod/us-east-1/record/terraform.tfstate`.

6. Confirm the objects:

```bash
aws s3 ls "s3://DEV-BUCKET/dev/us-east-1/record/"
aws s3 ls "s3://PROD-BUCKET/prod/us-east-1/record/"
terragrunt output
```

Run the `aws s3 ls` commands with credentials for the account that owns the bucket, or after assuming that account's role. During apply, Terraform creates `<key>.tflock` and removes it when the lock is released.

The lock file next to each unit pins `aws` 6.71.0, `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. `versions.tf` in the module is the only `required_providers` block.

7. Destroy both units:

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

8. Remove the state objects, then the buckets. `terragrunt backend delete`, run from a unit, deletes that unit's state object. It leaves the bucket. Versioning is on, so `aws s3 rb s3://YOUR-BUCKET --force` fails while noncurrent versions remain. In the S3 console, empty the bucket (that action deletes versions) and delete it. Delete the role when you are finished with the account.

## If bootstrap or plan stops early

- `NoSuchBucket`, or an init error that the bucket does not exist, means bootstrap has not created it yet. Run `terragrunt backend bootstrap` from the unit, or pass `--backend-bootstrap` on the run.
- `BucketAlreadyExists` means the name is taken by another account. Pick a different `state_bucket`. Names are global.
- `AccessDenied` on `AssumeRole` means the trust policy in that account does not name the caller. Dev and prod each have their own role. A trust policy in dev does not cover prod.
- An error that `terragrunt-labs` cannot assume `terragrunt-labs` means `assume_role` is in the provider stub, or `role_arn` is set inside `remote_state`. Take that line out. `iam_role` is the assume for this lecture.
- `use_lockfile = "true"` (quoted) is a string. Terraform wants the boolean `true`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- The checker fails when the two unit files differ, when a value is still `TODO`, or when dev and prod share an account id or a bucket name.
- `hcl fmt --check` fails when the alignment differs from the snippet above. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/dev/us-east-1/record/terragrunt.hcl`](solution/dev/us-east-1/record/terragrunt.hcl). The prod copy is the same file. What the checker prints, and what bootstrap creates, is written up in [`solution/NOTES.md`](solution/NOTES.md).
