# Prod unit. From this directory:
#   terragrunt run plan
# From the lecture start/ directory: ./check.sh
#
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
  note        = "local remote state"
}
