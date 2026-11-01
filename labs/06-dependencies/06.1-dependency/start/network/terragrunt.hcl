# Network unit. The service unit reads the name output from this unit.
# From this directory: terragrunt run plan
# From the lecture directory: ./check.sh
#
# terraform_binary comes from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "net"
  note        = "network unit"
}
