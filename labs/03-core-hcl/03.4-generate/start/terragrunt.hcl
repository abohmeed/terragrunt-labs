# Generate lab. Add generate blocks for versions.tf and provider.tf, then:
#   terragrunt run plan
#   ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  source = "./modules/note"
}

# TODO: generate versions.tf and provider.tf into the working copy.
# Use if_exists = "overwrite_terragrunt".
# versions.tf must require Terraform >= 1.17.0, < 1.18.0 and the local, null,
# and random providers at the same constraints as lecture 02.2.
# provider.tf must declare provider "local", provider "null", and provider "random".

inputs = {
  prefix = "lab"
  note   = "generated provider files"
}
