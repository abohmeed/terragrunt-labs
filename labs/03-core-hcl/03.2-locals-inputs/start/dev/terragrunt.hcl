# Dev unit. Fill in the locals and inputs, then from this directory:
#   terragrunt run plan
#
# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

locals {
  # TODO: set environment to "dev" and prefix_root to "lab".
  environment = ""
  prefix_root = ""
  prefix      = "${local.environment}-${local.prefix_root}"
  note        = "offline locals and inputs"
}

terraform {
  source = "../modules/record"
}

inputs = {
  # TODO: pass environment, prefix, and note. Terraform receives inputs, not locals.
}
