# Shared unit. The 0.x tree included _envcommon/record.hcl from every live unit.
# A stack file passes environment, prefix, and note as values.

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
