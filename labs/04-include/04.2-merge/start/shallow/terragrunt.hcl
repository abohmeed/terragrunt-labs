# Shallow merge. Set merge_strategy, then from this directory:
#   terragrunt render
# From the lecture start/ directory: ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
  # TODO: merge_strategy = "shallow"
}

terraform {
  source = "../modules/record"
}

inputs = {
  prefix = "shallow"
  note   = "from the unit"
  tags = {
    tier = "app"
  }
  labels = ["unit"]
}
