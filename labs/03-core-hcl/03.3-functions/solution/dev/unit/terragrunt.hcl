# Functions lab. From this directory:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root_cfg   = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  region_cfg = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_cfg    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  course      = local.root_cfg.locals.course
  region      = local.region_cfg.locals.region
  environment = local.env_cfg.locals.environment
  prefix      = "${local.environment}-${local.region}-${local.env_cfg.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
  note        = get_env("LAB_NOTE", "offline functions lab")
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
