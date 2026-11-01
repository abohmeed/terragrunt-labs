output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "course" {
  description = "Course name merged from root.hcl."
  value       = var.course
}

output "prefix" {
  description = "Prefix for the generated name. Each unit sets its own."
  value       = var.prefix
}

output "note" {
  description = "Sentence stored with the generated name."
  value       = var.note
}

output "owner" {
  description = "tags.owner after the merge. Empty when the child map replaced the root map."
  value       = lookup(var.tags, "owner", "")
}

output "tier" {
  description = "tags.tier after the merge."
  value       = var.tags["tier"]
}

output "cost_center" {
  description = "tags.cost_center after the merge. Empty when the child map replaced the root map."
  value       = lookup(var.tags, "cost_center", "")
}

output "labels" {
  description = "Labels joined with commas, in merge order."
  value       = join(",", var.labels)
}
