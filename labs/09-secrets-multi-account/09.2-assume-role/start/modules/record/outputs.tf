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
  description = "Sentence stored with the generated name."
  value       = var.note
}
