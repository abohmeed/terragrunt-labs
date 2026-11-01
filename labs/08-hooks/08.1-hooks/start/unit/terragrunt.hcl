# Hooks lab. Add before_hook, after_hook, and error_hook, then from start/:
#   terragrunt --working-dir unit run -- plan
#   terragrunt --working-dir unit run -- plan -var note=fail
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"

  # TODO: before_hook "stamp_start" for plan and apply.
  # Echo "before hook: plan starts".
  # TODO: after_hook "stamp_done" for plan and apply.
  # Echo "after hook: plan finished" and set run_on_error = false.
  # TODO: error_hook "stamp_error" for plan and apply.
  # Echo "error hook: plan failed".
  # on_errors matches "deliberate plan failure".
}

inputs = {
  environment = "dev"
  prefix      = "hook"
  note        = "hooks lab"
}
