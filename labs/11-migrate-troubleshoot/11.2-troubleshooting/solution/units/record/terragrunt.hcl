# Unit under test. live/ generates this directory.
# The note is a local so render has a value to resolve.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

locals {
  note = "traced from render"
}

inputs = {
  environment = "dev"
  prefix      = "dbg"
  note        = local.note
}
