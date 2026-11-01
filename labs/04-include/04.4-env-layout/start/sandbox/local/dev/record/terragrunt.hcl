# Account / region / env / unit. Replace the TODOs, then from this directory:
#   terragrunt run plan
# From the lecture start/ directory: ./check.sh
#
# dev/record and prod/record stay the same file. env.hcl is what changes.

# TODO: include root, account, region, and env.
# Expose each one. Merge root (it holds terraform_binary).
# Set merge_strategy = "no_merge" on account, region, and env.

locals {
  # TODO: read include.root, include.account, include.region, and include.env.
  # TODO: set unit_path with path_relative_to_include("root").
  course      = "TODO"
  account     = "TODO"
  region      = "TODO"
  environment = "TODO"
  prefix      = "TODO"
  unit_path   = "TODO"
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  course      = local.course
  account     = local.account
  region      = local.region
  environment = local.environment
  prefix      = local.prefix
  unit_path   = local.unit_path
}
