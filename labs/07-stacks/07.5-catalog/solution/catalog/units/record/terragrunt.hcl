# Catalog unit. stack files reference this directory. They do not copy it by hand.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "cat"
  note        = "catalog unit"
}
