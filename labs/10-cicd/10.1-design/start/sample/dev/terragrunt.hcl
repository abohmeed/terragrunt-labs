# dev unit for the pipeline sketch.
# From the lecture directory: ./check.sh
#
# terraform_binary and remote_state come from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "dev-lab"
  note        = "ci design"
}
