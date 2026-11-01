# api unit. Reads the network name. Run queue commands from apps/.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

dependency "network" {
  config_path = "../../network"

  mock_outputs = {
    name = "mock-network-name"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
}

inputs = {
  environment = "dev"
  prefix      = "api"
  note        = dependency.network.outputs.name
}
