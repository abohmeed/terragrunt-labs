# Shared 0.x config. dev/record and prod/record include this file.
# Terragrunt 1.x uses a unit in a stack instead of this include.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/record"
}

inputs = {
  prefix = "rec"
  note   = "from envcommon"
}
