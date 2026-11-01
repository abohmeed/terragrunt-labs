# Catalog stack. Discovery classifies this directory as a stack.
# Live environments pass their own values and do not generate this file.

unit "network" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/units/record"
  path   = "network"
}
