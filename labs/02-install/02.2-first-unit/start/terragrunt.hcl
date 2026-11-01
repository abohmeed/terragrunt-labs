# First unit. Finish the two TODOs, then run:
#   terragrunt run plan

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  # TODO: point this at the local module in ./modules/marker
  source = "./modules/TODO"
}

inputs = {
  # TODO: set prefix to a short string, for example "lab".
  # Until you do, plan prompts for var.prefix.
  note = "offline first unit"
}
