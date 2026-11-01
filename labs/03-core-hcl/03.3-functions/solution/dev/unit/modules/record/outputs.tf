output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "course" {
  description = "Course name read from root.hcl."
  value       = var.course
}

output "region" {
  description = "Region read from region.hcl. Offline labs use local."
  value       = var.region
}

output "environment" {
  description = "Environment read from env.hcl."
  value       = var.environment
}

output "prefix" {
  description = "Prefix derived from the environment, region, and env.hcl."
  value       = var.prefix
}

output "unit_path" {
  description = "Path of this unit relative to root.hcl."
  value       = var.unit_path
}

output "note" {
  description = "Sentence from LAB_NOTE, or the default when that variable is unset."
  value       = var.note
}

