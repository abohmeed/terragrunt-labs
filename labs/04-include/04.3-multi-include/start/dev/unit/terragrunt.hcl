# Multiple includes. Replace the TODOs, then from this directory:
#   terragrunt run plan
# From the lecture start/ directory: ./check.sh

# TODO: include root.hcl, region.hcl, and env.hcl.
# Expose each one. Merge root (it holds terraform_binary).
# Set merge_strategy = "no_merge" on region and env.

locals {
  # TODO: read include.root.locals, include.region.locals, and include.env.locals.
  # TODO: set unit_path with path_relative_to_include("root").
  course      = "TODO"
  region      = "TODO"
  environment = "TODO"
  prefix      = "TODO"
  unit_path   = "TODO"
  note        = "TODO"
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
