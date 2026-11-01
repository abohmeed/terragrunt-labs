output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "environment" {
  description = "Workspace name. terraform.workspace selects it."
  value       = local.environment
}

output "note" {
  description = "Sentence stored with the generated name."
  value       = local.note
}
