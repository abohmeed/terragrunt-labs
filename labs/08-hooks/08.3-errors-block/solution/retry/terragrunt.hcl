# Retry lab. From the lab root:
#   terragrunt --working-dir retry run -- apply -auto-approve
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/flaky"
}

inputs = {
  # The counter has to sit outside .terragrunt-cache. A retry that recopies
  # the module would otherwise reset an in-module file and fail forever.
  attempt_file = "${get_terragrunt_dir()}/attempt.count"
}

errors {
  retry "transient_network" {
    retryable_errors   = [".*Error: transient.*"]
    max_attempts       = 3
    sleep_interval_sec = 1
  }
}
