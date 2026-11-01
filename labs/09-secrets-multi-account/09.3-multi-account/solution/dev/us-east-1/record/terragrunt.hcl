# Account / region / unit. From this directory, once the account id and
# bucket name are yours:
#   terragrunt backend bootstrap
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# dev and prod keep this same file. account.hcl is what changes.
# The checker renders this unit. It does not call AWS.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "account" {
  path           = find_in_parent_folders("account.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

include "region" {
  path           = find_in_parent_folders("region.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

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

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  account_name = local.account_name
  account_id   = local.account_id
  aws_region   = local.aws_region
  role_arn     = local.role_arn
  unit_path    = local.unit_path
  note         = "multi account"
}
