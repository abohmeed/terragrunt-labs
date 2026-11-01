# Multiple includes. From this directory:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# The root include merges terraform_binary. Region and env are data, so they
# are exposed and not merged.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
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
  region      = include.region.locals.region
  environment = include.env.locals.environment
  prefix      = "${local.environment}-${local.region}-${include.env.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
  note        = "exposed includes"
}

terraform {
  source = "./modules/record"
}

inputs = {
  course      = local.course
  region      = local.region
  environment = local.environment
  prefix      = local.prefix
  unit_path   = local.unit_path
  note        = local.note
}
