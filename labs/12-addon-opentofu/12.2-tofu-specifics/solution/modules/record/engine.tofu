# OpenTofu reads this file instead of engine.tf. Terraform ignores .tofu files.

output "engine_file" {
  value = "tofu"
}
