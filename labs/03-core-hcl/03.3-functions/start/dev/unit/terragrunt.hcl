# Functions lab. Replace the TODOs, then from this directory:
#   terragrunt run plan
# From the lecture start/ directory: ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

include "root" {
  # TODO: find root.hcl in a parent directory.
  path = find_in_parent_folders("TODO")
}

locals {
  # TODO: read root.hcl, region.hcl, and env.hcl with read_terragrunt_config.
  # TODO: set unit_path with path_relative_to_include("root").
  # TODO: set note with get_env("LAB_NOTE", "offline functions lab").
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
