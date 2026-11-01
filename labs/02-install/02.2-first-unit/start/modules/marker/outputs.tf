output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "marker_path" {
  description = "Marker file written inside the Terragrunt working copy of this module."
  value       = local_file.marker.filename
}
