# Network unit. service reads this unit's name output when the queue applies.
# From the lecture directory: ./check.sh
#
# terraform_binary and remote_state come from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "net"
  note        = "apply on merge"
}
