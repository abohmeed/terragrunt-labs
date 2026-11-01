# One unit: a directory with this file.
# source points at one shared module. inputs are the values for this unit.
# Lecture 02.2 is the first `terragrunt run plan`. Do not run it in this lecture.

# Terragrunt 1.2 runs OpenTofu when `tofu` is on PATH. This course uses Terraform.
terraform_binary = "terraform"

terraform {
  source = "../modules/record"
}

inputs = {
  prefix = "dev"
  note   = "one unit, one module"
}
