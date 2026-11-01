# Record unit for the stack at the lecture root.
# terraform_binary comes from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = values.environment
  prefix      = values.prefix
  note        = values.note
}
