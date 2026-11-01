output "name" {
  description = "Generated name from the label module. Known after apply."
  value       = module.label.name
}

output "marker_path" {
  description = "Marker file written inside the staged copy of the label module."
  value       = module.label.marker_path
}
