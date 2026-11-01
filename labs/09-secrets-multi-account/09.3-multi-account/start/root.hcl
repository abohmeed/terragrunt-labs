# Shared settings for every unit in this multi-account tree.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Terragrunt 1.2 runs OpenTofu when tofu is on PATH. This course uses Terraform.

terraform_binary = "terraform"
