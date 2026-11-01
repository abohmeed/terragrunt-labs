# Nested stack. stack generate copies this file to .terragrunt-stack/platform
# and only then generates its units. A ../ path written for blueprints/platform
# would be resolved from that generated directory. Anchor the source on root.hcl.

unit "record" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/units/record"
  path   = "record"
}
