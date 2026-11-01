# dev stack. Both units come from the catalog. Service reads the network name at apply time.

unit "network" {
  source = "TODO"
  path   = "network"

  values = {
    environment = "dev"
    prefix      = "dev"
    note        = "dev network"
  }
}

unit "service" {
  source = "TODO"
  path   = "service"

  values = {
    environment = "dev"
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
