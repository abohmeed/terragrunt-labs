# Prod unit. From this directory, once the bucket name is yours:
#   terragrunt backend bootstrap
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# The checker renders this unit. It does not call AWS.
# terraform_binary and remote_state come from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = "prod"
  prefix      = "prod-lab"
  note        = "s3 remote state"
}
