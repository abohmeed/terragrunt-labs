# fmt, validate, and render. From this directory:
#   terragrunt hcl fmt
#   ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

locals {
environment = "dev"
prefix = "lab"
note = "rendered offline"
}

terraform {
source = "./modules/record"
}

inputs = {
environment = local.environment
prefix = local.prefix
note = local.note
}
