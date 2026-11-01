# Catalog unit. Live stacks reference this directory with the // source.
# A unit block that sets values replaces terragrunt.values.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/modules/record"
}

inputs = {
  environment = values.environment
  prefix      = values.prefix
  note        = values.note
}
