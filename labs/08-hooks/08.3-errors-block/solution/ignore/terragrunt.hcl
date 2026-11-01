# Ignore lab. From the lab root:
#   terragrunt --working-dir ignore run -- apply -auto-approve
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/drift"
}

# Ignore is evaluated before retry. A matching ignore does not retry.
# The leading ! on a pattern keeps that error from being ignored.
errors {
  ignore "known_drift" {
    ignorable_errors = [
      ".*Error: safe-to-ignore.*",
      "!.*Error: do not ignore.*",
    ]
    message = "Ignoring safe-to-ignore drift"
    signals = {
      safe_to_revert = true
    }
  }
}
