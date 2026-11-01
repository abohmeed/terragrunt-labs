# Prod account. Named account.hcl so this directory is not a unit.
# Replace the account id and the bucket name before bootstrap.
# 222222222222 is a placeholder. Use a different bucket from dev.

locals {
  account_name = "prod"
  account_id   = "222222222222"
  role_name    = "terragrunt-labs"
  role_arn     = "arn:aws:iam::${local.account_id}:role/${local.role_name}"
  state_bucket = "example-terragrunt-labs-prod-state"
}
