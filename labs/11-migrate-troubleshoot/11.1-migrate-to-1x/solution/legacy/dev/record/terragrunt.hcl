# 0.x live unit. It includes _envcommon instead of declaring the module itself.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/record.hcl"
  expose = true
}

inputs = {
  environment = "dev"
  prefix      = "dev"
  note        = "dev envcommon"
}
