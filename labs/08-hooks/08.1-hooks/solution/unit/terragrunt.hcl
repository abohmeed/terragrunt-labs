# Hooks lab. From the lab root:
#   terragrunt --working-dir unit run -- plan
#   terragrunt --working-dir unit run -- plan -var note=fail
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"

  # Runs in the module copy before Terraform. A non-zero status skips Terraform.
  before_hook "stamp_start" {
    commands = ["plan", "apply"]
    execute  = ["echo", "before hook: plan starts"]
  }

  # Runs after Terraform. run_on_error = false skips this hook when the plan fails.
  after_hook "stamp_done" {
    commands     = ["plan", "apply"]
    execute      = ["echo", "after hook: plan finished"]
    run_on_error = false
  }

  # Runs only when Terraform fails and the output matches on_errors.
  error_hook "stamp_error" {
    commands  = ["plan", "apply"]
    execute   = ["echo", "error hook: plan failed"]
    on_errors = [".*deliberate plan failure.*"]
  }
}

inputs = {
  environment = "dev"
  prefix      = "hook"
  note        = "hooks lab"
}
