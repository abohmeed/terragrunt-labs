# Legacy environment unit. The terraform source lives in _envcommon/record.hcl.
# This is the shape stacks replace.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/record.hcl"
}

inputs = {
  environment = "dev"
  prefix      = "old"
  note        = "legacy include"
}
