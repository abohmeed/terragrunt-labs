# Deep merge. Set merge_strategy, then from this directory:
#   terragrunt render
# From the lecture start/ directory: ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
  # TODO: merge_strategy = "deep"
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
