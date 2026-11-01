# Shared network unit. From apps/, this path is outside the working directory,
# so it is an external dependency.

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
