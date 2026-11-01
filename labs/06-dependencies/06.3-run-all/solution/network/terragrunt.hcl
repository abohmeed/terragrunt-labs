# Network unit. database reads this unit's name output.
# From the lecture directory: terragrunt run --all plan

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
