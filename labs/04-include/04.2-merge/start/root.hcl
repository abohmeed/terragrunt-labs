# Shared inputs for the shallow, deep, and no_merge units.
# Named root.hcl so Terragrunt does not treat this directory as a unit.

terraform_binary = "terraform"

inputs = {
  course = "terragrunt-labs"
  note   = "from root"
  tags = {
    owner       = "platform"
    tier        = "shared"
    cost_center = "labs"
  }
  labels = ["course", "shared"]
}
