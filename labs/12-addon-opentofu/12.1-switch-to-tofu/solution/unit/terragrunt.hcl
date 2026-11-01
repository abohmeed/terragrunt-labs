# Switch-to-tofu unit. terraform_binary comes from root.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "tofu"
  note        = "switched to tofu"
}
