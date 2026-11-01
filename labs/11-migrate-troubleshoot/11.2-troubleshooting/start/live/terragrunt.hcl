# Bug: this directory is a stack. A stack cannot also contain terragrunt.hcl.
# Delete this file. The unit lives in units/record.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "bad"
  note        = "ambiguous directory"
}
