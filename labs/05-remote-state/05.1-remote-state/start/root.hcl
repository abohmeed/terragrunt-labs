# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# The units inherit terraform_binary. Finish the remote_state path.

terraform_binary = "terraform"

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # TODO: absolute path, one state file per unit, under state/<unit>/terraform.tfstate.
    path = "TODO"
  }
}
