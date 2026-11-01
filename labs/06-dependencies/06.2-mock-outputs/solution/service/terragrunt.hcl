# Service unit. Mocks stand in for the network name until that unit is applied.
# From this directory: terragrunt run plan
# From the lecture directory: ./check.sh

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
