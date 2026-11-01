output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "environment" {
  description = "Environment name. Set by the unit, not by this module."
  value       = var.environment
}

output "prefix" {
  description = "Prefix for the generated name."
  value       = var.prefix
}

output "note" {
  description = "Sentence decrypted from the SOPS file."
  value       = var.note
}

output "db_password" {
  description = "Lab fixture decrypted from the SOPS file. It is not a real credential."
  value       = var.db_password
  sensitive   = true
}

output "age_key_configured" {
  description = "True when SOPS_AGE_KEY_FILE is set to a non-empty path."
  value       = var.age_key_configured
}
