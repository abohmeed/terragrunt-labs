# no_merge. From this directory:
#   terragrunt render
# From the lecture directory (start/ or solution/): ./check.sh
#
# no_merge does not inherit terraform_binary. This unit sets it.

include "root" {
  path           = find_in_parent_folders("root.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform_binary = "terraform"

terraform {
  source = "../modules/record"
}

inputs = {
  course = include.root.inputs.course
  prefix = "no-merge"
  note   = "from the unit"
  tags = {
    tier = "app"
  }
  labels = ["unit"]
}
