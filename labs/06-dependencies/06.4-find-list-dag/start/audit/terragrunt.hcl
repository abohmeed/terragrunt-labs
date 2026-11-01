# Audit unit. It depends on no other unit, so the DAG shows it beside network.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "audit"
  note        = "audit unit"
}
