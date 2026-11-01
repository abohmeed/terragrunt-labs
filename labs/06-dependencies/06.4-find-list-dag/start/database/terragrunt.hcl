# Database unit. Depends on network. service reads this unit's name output.

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
  prefix      = "db"
  note        = dependency.network.outputs.name
}
