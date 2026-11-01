# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# remote_state generates backend.tf in the working copy. The local backend
# writes state under state/<unit>/, outside the unit directory and outside
# .terragrunt-cache.

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
