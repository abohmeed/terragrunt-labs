# Shared settings for the assume-role unit.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Finish iam_role and the generated provider. The checker does not call AWS.
# Replace 111111111111 with your account id before you plan.

terraform_binary = "terraform"

locals {
  aws_region = "us-east-1"
  account_id = "111111111111"
  role_arn   = "arn:aws:iam::${local.account_id}:role/terragrunt-labs"
}

# TODO: iam_role = local.role_arn
# Terragrunt assumes that role and exports the session before Terraform runs.

# TODO: generate "provider" writing provider.tf.
# if_exists = "overwrite_terragrunt"
# provider "aws" sets region from local.aws_region.
# Leave assume_role out. The session already belongs to local.role_arn.
