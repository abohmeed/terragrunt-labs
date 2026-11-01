# CLI practice unit. From this directory:
#   ./exercises.sh
# or the commands in the lecture README.

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  source = "./modules/marker"
}

inputs = {
  prefix = "lab"
  note   = "offline first unit"
}
