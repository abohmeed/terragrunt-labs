# no_merge. Expose the root, set merge_strategy, and set terraform_binary.
# From this directory:
#   terragrunt render
# From the lecture start/ directory: ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
  # TODO: expose = true
  # TODO: merge_strategy = "no_merge"
}

# TODO: set terraform_binary = "terraform". no_merge does not inherit it.

terraform {
  source = "../modules/record"
}

inputs = {
  # TODO: set course from include.root.inputs.course.
  course = "TODO"
  prefix = "no-merge"
  note   = "from the unit"
  tags = {
    tier = "app"
  }
  labels = ["unit"]
}
