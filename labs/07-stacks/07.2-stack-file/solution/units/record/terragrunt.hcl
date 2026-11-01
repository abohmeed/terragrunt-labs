# Record unit used by the edge unit and by the nested platform stack.
# terraform_binary comes from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "rec"
  note        = "record unit"
}
