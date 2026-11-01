output "name" {
  description = "Generated name. Known after apply."
  value       = random_pet.name.id
}

output "account_name" {
  description = "Account name read from the exposed account include."
  value       = var.account_name
}

output "account_id" {
  description = "AWS account id read from the exposed account include."
  value       = var.account_id
}

output "aws_region" {
  description = "Region read from the exposed region include."
  value       = var.aws_region
}

output "role_arn" {
  description = "IAM role Terragrunt assumes for this account."
  value       = var.role_arn
}

output "unit_path" {
  description = "Path of this unit relative to root.hcl."
  value       = var.unit_path
}

output "note" {
  description = "Sentence stored with the generated name."
  value       = var.note
}
