# Dev directory. From this directory:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# The environment is the directory. This unit stays on the default workspace.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "dev-lab"
  note        = "directory per environment"
}
