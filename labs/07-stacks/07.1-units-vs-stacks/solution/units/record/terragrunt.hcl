# Record unit. One terragrunt.hcl is one Terraform run.
# terraform_binary comes from root.hcl. This file does not include _envcommon.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "unit"
  note        = "one unit"
}
