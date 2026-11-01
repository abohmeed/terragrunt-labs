# Account / region / unit. Replace the TODOs, then from start/:
#   ./check.sh
#
# dev and prod keep this same file. account.hcl is what changes.
# The checker renders the units. It does not call AWS.

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
  # TODO: read include.account and include.region.
  # TODO: set unit_path with path_relative_to_include("root").
  account_name = "TODO"
  account_id   = "TODO"
  role_arn     = "TODO"
  state_bucket = "TODO"
  aws_region   = "TODO"
  unit_path    = "TODO"
}

# TODO: iam_role = local.role_arn

# TODO: remote_state backend "s3".
# generate backend.tf with if_exists = "overwrite_terragrunt".
# bucket = local.state_bucket
# key    = "${path_relative_to_include("root")}/terraform.tfstate"
# region = local.aws_region
# encrypt = true
# use_lockfile = true
# Leave role_arn unset in this block.

# TODO: generate "provider" writing provider.tf.
# if_exists = "overwrite_terragrunt"
# provider "aws" sets region from local.aws_region.
# Leave assume_role out.

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
