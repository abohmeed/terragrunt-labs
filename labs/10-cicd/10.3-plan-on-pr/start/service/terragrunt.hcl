# Service unit. Plan uses the network mock. Apply is lecture 10.4.
# From the lecture directory: ./check.sh
#
# terraform_binary and remote_state come from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    name = "mock-network-name"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = "dev"
  prefix      = "svc"
  note        = dependency.network.outputs.name
}
