# Shared settings for the assume-role unit.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Replace 111111111111 with your account id before you plan.
# The checker renders the unit. It does not call AWS.
#
# iam_role makes Terragrunt assume the role and export that session.
# The generated provider sets the region and uses the session.

terraform_binary = "terraform"

locals {
  aws_region = "us-east-1"
  account_id = "111111111111"
  role_arn   = "arn:aws:iam::${local.account_id}:role/terragrunt-labs"
}

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
