# Root include lab. From this directory:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# The root file sets terraform_binary. This unit inherits it.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "./modules/record"
}

inputs = {
  prefix = "lab"
  note   = "from the unit"
}
