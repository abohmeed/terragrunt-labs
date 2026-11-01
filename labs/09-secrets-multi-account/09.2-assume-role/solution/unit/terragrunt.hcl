# Assume-role unit. From this directory, once the account id is yours:
#   terragrunt run plan
# From the lecture directory (start/ or solution/): ./check.sh
#
# The checker renders this unit. It does not call AWS.
# terraform_binary, iam_role, and the provider stub come from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "assume"
  note        = "assume role"
}
