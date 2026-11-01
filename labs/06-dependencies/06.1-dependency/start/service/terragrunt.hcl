# Service unit. Read the network unit's name output.
# From this directory: terragrunt run plan
# From the lecture directory: ./check.sh
#
# TODO: add a dependency "network" block with config_path = "../network".
# Set inputs.note to dependency.network.outputs.name.
# Do not add mock_outputs. Lecture 06.2 covers those.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "svc"
  note        = "TODO"
}
