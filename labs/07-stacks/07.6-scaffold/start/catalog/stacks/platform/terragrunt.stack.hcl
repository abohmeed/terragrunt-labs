# Catalog stack. scaffold copies this file and writes terragrunt.values.hcl
# from the values.* references in this stack.

unit "record" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/catalog/units/record"
  path   = "record"

  values = {
    environment = values.environment
    prefix      = values.prefix
    note        = try(values.note, "stack note")
  }
}
