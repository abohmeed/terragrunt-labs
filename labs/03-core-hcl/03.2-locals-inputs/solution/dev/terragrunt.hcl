# Dev unit. From this directory:
#   terragrunt run plan
#
# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

locals {
  environment = "dev"
  prefix_root = "lab"
  prefix      = "${local.environment}-${local.prefix_root}"
  note        = "offline locals and inputs"
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = local.environment
  prefix      = local.prefix
  note        = local.note
}
