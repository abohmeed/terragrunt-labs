# Source lab. From this directory:
#   terragrunt run plan
#   ./check.sh

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  # Copy this directory, then run modules/service inside the copy.
  # The // is Terragrunt syntax: <directory to copy>//<root module>.
  source = "${get_terragrunt_dir()}//modules/service"
}

inputs = {
  prefix = "lab"
  note   = "offline source lab"
}
