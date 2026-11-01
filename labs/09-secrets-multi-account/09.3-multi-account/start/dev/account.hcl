# Dev account. Named account.hcl so this directory is not a unit.
# Replace the account id and the bucket name before bootstrap.
# 111111111111 is a placeholder. Bucket names are global.

locals {
  account_name = "dev"
  account_id   = "111111111111"
  role_name    = "terragrunt-labs"
  role_arn     = "arn:aws:iam::${local.account_id}:role/${local.role_name}"
  state_bucket = "example-terragrunt-labs-dev-state"
}
