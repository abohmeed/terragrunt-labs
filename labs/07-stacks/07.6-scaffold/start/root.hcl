# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Terragrunt 1.2 runs OpenTofu when tofu is on PATH. This course uses Terraform.
# The catalog URL is a local directory. terragrunt catalog treats it as a Git repository.

terraform_binary = "terraform"

catalog {
  urls = [
    "./catalog",
  ]
}
