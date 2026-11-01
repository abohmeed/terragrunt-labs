# Service unit. The dependency block is in place. Plan still needs the network
# unit to be applied, because this file has no mock outputs yet.
# From this directory: terragrunt run plan
# From the lecture directory: ./check.sh
#
# TODO: mock the network name output with the value mock-network-name.
# Allow those mocks for the validate and plan commands only.

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
