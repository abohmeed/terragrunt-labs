# SOPS unit. From the lecture directory (start/ or solution/): ./check.sh
#
# SOPS_AGE_KEY_FILE points at an age private key outside this repo.
# sops_decrypt_file reads secrets.enc.yaml with that key.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  age_key_file = get_env("SOPS_AGE_KEY_FILE")
  secrets      = yamldecode(sops_decrypt_file(find_in_parent_folders("secrets.enc.yaml")))
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment        = "dev"
  prefix             = "sops"
  note               = local.secrets.note
  db_password        = local.secrets.db_password
  age_key_configured = length(trimspace(local.age_key_file)) > 0
}
