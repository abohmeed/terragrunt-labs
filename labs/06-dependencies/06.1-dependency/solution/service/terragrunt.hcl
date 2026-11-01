# Service unit. note is the network unit's name output.
# From this directory: terragrunt run plan
# From the lecture directory: ./check.sh
#
# Apply network before planning this unit. This lecture does not use mock outputs.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  prefix      = "svc"
  note        = dependency.network.outputs.name
}
