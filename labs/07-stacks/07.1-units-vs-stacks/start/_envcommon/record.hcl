# The 0.x shared partial. This directory is not a unit: there is no terragrunt.hcl.
# legacy/dev and legacy/prod include this file so they do not repeat the source.
# A stack does not include it. The unit under units/record is the replacement.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}
