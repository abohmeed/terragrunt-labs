# Stack for this lecture. Run terragrunt stack generate and terragrunt stack run
# from this directory. The record unit stays in ../units, outside this directory.
# stack run discovers every unit under the working directory, and the source
# unit has no terragrunt.values.hcl until generate writes one.

unit "network" {
  source = "../units/record"
  path   = "network"

  values = {
    environment = "dev"
    prefix      = "net"
    note        = "network unit"
  }
}

unit "service" {
  source = "../units/record"
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
