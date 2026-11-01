# Account / region / env / unit. From this directory:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# dev/record and prod/record keep this same file. env.hcl is what changes.
# The root include merges terraform_binary. The other includes are data.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
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

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

locals {
  course      = include.root.locals.course
  account     = include.account.locals.account_name
  region      = include.region.locals.region
  environment = include.env.locals.environment
  prefix      = "${local.account}-${local.environment}-${include.env.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
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
