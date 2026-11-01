# Shared settings for every unit that includes this file.
# Named root.hcl so Terragrunt does not treat this directory as a unit.
#
# Finish the S3 remote_state block. The checker does not call AWS.

terraform_binary = "terraform"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # TODO: a globally unique, lowercase bucket name.
    bucket = "TODO"
    # TODO: one key per unit, from path_relative_to_include().
    key    = "TODO"
    region = "us-east-1"
    # TODO: encrypt the state object, and lock with the S3 lock file.
    encrypt      = false
    use_lockfile = false
  }
}
