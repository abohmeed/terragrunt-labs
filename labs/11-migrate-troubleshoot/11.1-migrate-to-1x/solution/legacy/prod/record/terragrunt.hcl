# 0.x live unit. Same include as dev. The inputs are the prod override.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/record.hcl"
  expose = true
}

inputs = {
  environment = "prod"
  prefix      = "prd"
  note        = "prod envcommon"
}
