# Shared settings. The unit exposes this file and reads locals.course.
# Named root.hcl so Terragrunt does not treat this directory as a unit.

terraform_binary = "terraform"

locals {
  course = "terragrunt-labs"
}
