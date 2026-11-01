# prod stack. Both units come from the catalog. Service reads the network name at apply time.

unit "network" {
  source = "../../catalog//units/record"
  path   = "network"

  values = {
    environment = "prod"
    prefix      = "prd"
    note        = "prod network"
  }
}

unit "service" {
  source = "../../catalog//units/record"
  path   = "service"

  values = {
    environment = "prod"
    prefix      = "svc"
    note        = "replaced by the network output"
  }

  autoinclude {
    dependency "network" {
      config_path = unit.network.path

      mock_outputs = {
        name = "mock-network-name"
      }

      mock_outputs_allowed_terraform_commands = ["validate", "plan"]
    }

    inputs = {
      note = dependency.network.outputs.name
    }
  }
}
