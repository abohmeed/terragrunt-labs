# Lint hooks. Add before_hooks for tflint, terraform fmt, and checkov, then from start/:
#   terragrunt --working-dir unit run -- plan
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"

  # TODO: before_hook "tflint" for plan and apply.
  # execute = ["tflint", "--minimum-failure-severity=error"]
  # TODO: before_hook "fmt" for plan and apply.
  # execute = ["terraform", "fmt", "-check", "-diff"]
  # TODO: before_hook "checkov" for plan and apply.
  # Point execute at ${dirname(find_in_parent_folders("root.hcl"))}/hooks/checkov
  # with -d ., --framework terraform, --quiet, and --compact.
}

inputs = {
  environment = "dev"
  prefix      = "lint"
  note        = "lint hooks"
}
