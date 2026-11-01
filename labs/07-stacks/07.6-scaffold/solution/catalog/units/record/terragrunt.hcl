# Catalog unit. scaffold copies this file and writes terragrunt.values.hcl
# from the values.* references below.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/modules/record"
}

inputs = {
  environment = values.environment
  prefix      = values.prefix
  note        = try(values.note, "catalog note")
}
