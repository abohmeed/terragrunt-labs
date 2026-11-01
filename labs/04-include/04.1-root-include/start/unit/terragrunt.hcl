# Root include lab. Replace the TODOs, then from this directory:
#   terragrunt run plan
# From the lecture start/ directory: ./check.sh
#
# The root file sets terraform_binary. Leave that setting there.

include "root" {
  # TODO: find root.hcl in the parent directory.
  path = find_in_parent_folders("TODO")
}

terraform {
  source = "./modules/record"
}

inputs = {
  # TODO: set prefix to "lab" and note to "from the unit".
  # Leave course unset so the root input merges in.
  prefix = "TODO"
  note   = "TODO"
}
