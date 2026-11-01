# Lint hooks. From the lab root:
#   terragrunt --working-dir unit run -- plan
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"

  # Bare "tflint" (not an absolute path) tells Terragrunt to init plugins and
  # pass inputs as --var. The binary is the mise pin, not a file in this repo.
  before_hook "tflint" {
    commands = ["plan", "apply"]
    execute  = ["tflint", "--minimum-failure-severity=error"]
  }

  # fmt runs in the module copy under .terragrunt-cache. -check fails the hook,
  # and a failing before_hook never reaches Terraform.
  before_hook "fmt" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "fmt", "-check", "-diff"]
  }

  # Absolute path: the hook's working directory is the module copy, which does
  # not contain hooks/checkov. -d . scans that copy.
  before_hook "checkov" {
    commands = ["plan", "apply"]
    execute = [
      "${dirname(find_in_parent_folders("root.hcl"))}/hooks/checkov",
      "-d", ".",
      "--framework", "terraform",
      "--quiet",
      "--compact",
    ]
  }
}

inputs = {
  environment = "dev"
  prefix      = "lint"
  note        = "lint hooks"
}
