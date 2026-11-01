output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "note" {
  description = "Sentence stored with the generated name."
  value       = var.note
}
