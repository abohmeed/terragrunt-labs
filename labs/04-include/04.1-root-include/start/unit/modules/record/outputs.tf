output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "course" {
  description = "Course name merged from root.hcl."
  value       = var.course
}

output "prefix" {
  description = "Prefix for the generated name. The unit sets this."
  value       = var.prefix
}

output "note" {
  description = "Sentence stored with the generated name. The unit overrides the root value."
  value       = var.note
}
