# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Terragrunt 1.2 runs OpenTofu when tofu is on PATH. This course uses Terraform.
# Add a catalog block whose urls list is the local ./catalog directory.

terraform_binary = "terraform"
