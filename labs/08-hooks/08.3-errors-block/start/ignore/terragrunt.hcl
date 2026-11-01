# Ignore lab. Add an errors.ignore block, then from start/:
#   terragrunt --working-dir ignore run -- apply -auto-approve
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/drift"
}

# TODO: errors { ignore "known_drift" { ... } }
# Match "Error: safe-to-ignore" and exclude "Error: do not ignore".
# message = "Ignoring safe-to-ignore drift"
# signals = { safe_to_revert = true }
