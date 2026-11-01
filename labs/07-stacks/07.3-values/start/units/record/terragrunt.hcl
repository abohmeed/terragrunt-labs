# Record unit. environment, prefix, and note come from values.
# terragrunt.values.hcl next to this file is the default. A unit block that
# sets values replaces that file in the generated unit. It does not merge.

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
