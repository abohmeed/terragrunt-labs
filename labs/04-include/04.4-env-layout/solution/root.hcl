# Shared settings for every unit in this account/region/env tree.
# Named root.hcl so Terragrunt does not treat this directory as a unit.

terraform_binary = "terraform"

locals {
  course = "terragrunt-labs"
}
