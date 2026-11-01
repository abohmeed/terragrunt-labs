# SOPS unit. Wire sops_decrypt_file and get_env, then from start/:
#   export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
#   ./check.sh
#
# Keep the age private key outside this repo.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# TODO: locals.
# age_key_file reads get_env("SOPS_AGE_KEY_FILE") with no default.
# secrets is yamldecode of sops_decrypt_file on secrets.enc.yaml.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment = "dev"
  prefix      = "sops"
  # TODO: note and db_password from local.secrets.
  # TODO: age_key_configured is true when local.age_key_file is non-empty.
  note               = "TODO"
  db_password        = "TODO"
  age_key_configured = false
}
