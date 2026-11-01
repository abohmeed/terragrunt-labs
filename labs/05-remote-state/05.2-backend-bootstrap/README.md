# 05.2 Backend bootstrap ☁️

Point the `remote_state` block from lecture 05.1 at an S3 bucket, lock state with `use_lockfile`, and create that bucket with `terragrunt backend bootstrap`.

This lecture needs an AWS account for the bootstrap, plan, and apply. `./check.sh` does not call AWS. It checks the configuration and renders both units on your machine. Run the checker before you spend time on credentials.

## Goal

`start/root.hcl` uses the S3 backend:

| Setting | Value |
| --- | --- |
| `backend` | `"s3"` |
| `bucket` | A lowercase name that is unique across AWS. The file ships with `example-terragrunt-labs-state`. Replace that before bootstrap |
| `key` | `"${path_relative_to_include()}/terraform.tfstate"` so dev and prod get different objects |
| `region` | `us-east-1`, or another region you set in the same block |
| `encrypt` | `true` |
| `use_lockfile` | `true` |

`use_lockfile` is the S3 lock that Terraform 1.10 and later support. Terraform writes `<key>.tflock` beside the state object for the duration of the operation. Leave `dynamodb_table` unset. This lab does not create a DynamoDB table.

The resources in the unit stay on the `local`, `null`, and `random` providers. AWS is the state backend.

## Layout

```text
start/
  root.hcl                 # terraform_binary and the S3 remote_state block
  modules/record/
  dev/terragrunt.hcl       # key dev/terraform.tfstate
  prod/terragrunt.hcl      # key prod/terraform.tfstate
```

`generate` writes `backend.tf` into the working copy, the same way lecture 05.1 did for the local backend.

## Why bootstrap exists

Terraform will not create the bucket it stores state in. Something else has to create it first. `terragrunt backend bootstrap` reads `remote_state` and creates the bucket when it is missing. A second run sees the bucket and leaves it in place.

On a bucket Terragrunt creates, bootstrap turns on:

- versioning
- server-side encryption
- Block Public Access
- a bucket policy that requires TLS

It does not create a DynamoDB table when `dynamodb_table` is unset and `use_lockfile` is set.

The bucket's own configuration is not stored in the bucket. That avoids the loop of needing the bucket in order to store the state that creates the bucket.

## Offline steps

Do these before you use AWS. They are what `./check.sh` runs.

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Replace the TODOs in `start/root.hcl` with:

```hcl
config = {
  bucket       = "example-terragrunt-labs-state"
  key          = "${path_relative_to_include()}/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

`example-terragrunt-labs-state` is a placeholder so the render has a legal bucket name. The checker accepts any lowercase S3 bucket name. Put your own name in before the AWS steps below. S3 bucket names are global.

Keep `backend = "s3"` and the `generate` block. Do not add `dynamodb_table`. Do not set `disable_init = true`. `disable_init` stops Terragrunt from creating the bucket.

3. From `start/dev`:

```bash
terragrunt run -- version
terragrunt render
terragrunt render --format json
```

The version line is Terraform 1.17.x. The render shows `backend = "s3"`, your bucket, `key = "dev/terraform.tfstate"`, `encrypt = true`, and `use_lockfile = true`. The JSON form has `"use_lockfile":true` as a boolean. A quoted `"true"` is rejected by Terraform.

Repeat the render from `start/prod`. The key is `prod/terraform.tfstate`. The bucket and region match dev.

4. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  05.2 backend bootstrap
AWS was not contacted. Follow the README to bootstrap the bucket when you have credentials.
```

The script formats the HCL, checks the block, renders both units, and checks that every module variable is set. It does not run `backend bootstrap`, `plan`, or `apply`.

## AWS steps

Use a sandbox account. The identity needs to create and configure an S3 bucket (versioning, encryption, Block Public Access, and the TLS bucket policy) and to read and write objects in it, including the `.tflock` object. Bootstrap also calls `sts:GetCallerIdentity`.

Keep credentials in the environment (`AWS_PROFILE`, or `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`). Do not commit them.

1. Put your bucket name in `root.hcl`. From `start/`, `./check.sh` still passes.
2. From `start/dev`:

```bash
terragrunt --non-interactive backend bootstrap
terragrunt run -- version
terragrunt run plan
terragrunt --non-interactive run -- apply -auto-approve -input=false
```

`terragrunt --non-interactive run --backend-bootstrap -- apply -auto-approve -input=false` bootstraps and applies in one command. The flag is the same work as `backend bootstrap`.

3. From `start/prod`, run bootstrap and apply again. The bucket already exists. Prod's state object is `prod/terraform.tfstate`.

4. Confirm the objects:

```bash
aws s3 ls "s3://YOUR-BUCKET/dev/"
aws s3 ls "s3://YOUR-BUCKET/prod/"
terragrunt output
```

During apply, Terraform creates `dev/terraform.tfstate.tflock` and removes it when the lock is released. A lock file left behind means an apply is still running, or a run was interrupted. Wait for the apply, or break the lock only when you know nothing else is writing state.

Dev output has `environment = "dev"`, `prefix = "dev-lab"`, and `note = "s3 remote state"`. Prod has `environment = "prod"` and `prefix = "prod-lab"`.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. The S3 backend is built into Terraform. You do not install a separate backend provider.

5. Destroy both units:

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

6. Remove the state objects, then the bucket. `terragrunt backend delete`, run from a unit, deletes that unit's state object. It leaves the bucket. Versioning is on, so `aws s3 rb s3://YOUR-BUCKET --force` fails while noncurrent versions remain. In the S3 console, empty the bucket (that action deletes versions) and delete it.

## If bootstrap or plan stops early

- `NoSuchBucket`, or an init error that the bucket does not exist, means bootstrap has not created it yet. Run `terragrunt backend bootstrap` from the unit, or pass `--backend-bootstrap` on the run.
- `BucketAlreadyExists` means the name is taken by another account. Pick a different `bucket` value. Names are global.
- `use_lockfile = "true"` (quoted) is a string. Terraform wants the boolean `true`.
- A `dynamodb_table` argument makes Terragrunt create a DynamoDB table as well. This lecture leaves that argument out.
- `disable_init = true` writes `backend.tf` and then refuses to create the bucket.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- The checker fails on `bucket = "TODO"` or `key = "TODO"`. It also fails when the rendered key is not `dev/terraform.tfstate` or `prod/terraform.tfstate`.
- `hcl fmt --check` fails when the alignment differs from the snippet above. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your root file with [`solution/root.hcl`](solution/root.hcl). The units and the module match `start/`. What the checker prints, and what bootstrap creates, is written up in [`solution/NOTES.md`](solution/NOTES.md).
