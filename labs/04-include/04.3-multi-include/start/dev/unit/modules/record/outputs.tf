output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "course" {
  description = "Course name read from the exposed root include."
  value       = var.course
}

output "region" {
  description = "Region read from the exposed region include. Offline labs use local."
  value       = var.region
}

output "environment" {
  description = "Environment read from the exposed env include."
  value       = var.environment
}

output "prefix" {
  description = "Prefix derived from the environment, region, and env.hcl."
  value       = var.prefix
}

output "unit_path" {
  description = "Path of this unit relative to the root include."
  value       = var.unit_path
}

output "note" {
  description = "Sentence set by this unit."
  value       = var.note
}
