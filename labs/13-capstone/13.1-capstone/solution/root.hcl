# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Terragrunt 1.2 runs OpenTofu when tofu is on PATH. This course uses Terraform.
# The catalog URL is a local directory. State stays on the local backend.

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

catalog {
  urls = [
    "./catalog",
  ]
}
