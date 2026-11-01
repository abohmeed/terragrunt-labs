# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.

terraform_binary = "terraform"

inputs = {
  course = "terragrunt-labs"
  note   = "from root"
}
