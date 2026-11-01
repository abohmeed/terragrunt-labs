# Deep merge. From this directory:
#   terragrunt render
# From the lecture directory (start/ or solution/): ./check.sh
#
# The root file sets terraform_binary. This unit inherits it.

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "../modules/record"
}

inputs = {
  prefix = "deep"
  note   = "from the unit"
  tags = {
    tier = "app"
  }
  labels = ["unit"]
}
