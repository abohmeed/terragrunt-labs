# Generate lab. From this directory:
#   terragrunt run plan
#   ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  source = "./modules/note"
}

# The module ships no versions.tf and no provider.tf. These blocks write both
# into the working copy before Terraform runs. overwrite_terragrunt replaces
# a previous generated file and leaves a hand-written file alone.
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.17.0, < 1.18.0"

      required_providers {
        local = {
          source  = "hashicorp/local"
          version = "~> 2.5"
        }
        null = {
          source  = "hashicorp/null"
          version = "~> 3.2"
        }
        random = {
          source  = "hashicorp/random"
          version = "~> 3.6"
        }
      }
    }
  EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "local" {}

    provider "null" {}

    provider "random" {}
  EOF
}

inputs = {
  prefix = "lab"
  note   = "generated provider files"
}
