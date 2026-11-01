# Catalog stack. Discovery classifies this directory as a stack.
# The unit source is anchored on root.hcl so it still resolves after generate.

unit "record" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/units/record"
  path   = "record"
}
