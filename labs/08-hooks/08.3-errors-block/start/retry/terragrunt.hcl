# Retry lab. Add an errors.retry block, then from start/:
#   terragrunt --working-dir retry run -- apply -auto-approve
#   ./check.sh

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/flaky"
}

inputs = {
  attempt_file = "${get_terragrunt_dir()}/attempt.count"
}

# TODO: errors { retry "transient_network" { ... } }
# Match "Error: transient". max_attempts = 3. sleep_interval_sec = 1.
