# Shared settings for the directory-per-environment layout.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# This is the local remote_state block from lecture 05.1. Each unit writes
# state/<unit>/terraform.tfstate and stays on Terraform's default workspace.

terraform_binary = "terraform"

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate"
  }
}
