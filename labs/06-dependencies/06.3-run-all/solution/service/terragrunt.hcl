# Service unit. Depends on database, which depends on network.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

dependency "database" {
  config_path = "../database"

  mock_outputs = {
    name = "mock-db-name"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = "dev"
  prefix      = "svc"
  note        = dependency.database.outputs.name
}
