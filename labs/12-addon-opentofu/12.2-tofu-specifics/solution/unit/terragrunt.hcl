# OpenTofu specifics unit. terraform_binary comes from root.hcl.
# The module adds engine.tofu, which OpenTofu loads in place of engine.tf.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "tofu"
  note        = "tofu specifics"
}
