variable "account_name" {
  description = "Account name read from the exposed account include."
  type        = string
}

variable "account_id" {
  description = "AWS account id read from the exposed account include."
  type        = string
}

variable "aws_region" {
  description = "Region read from the exposed region include."
  type        = string
}

variable "role_arn" {
  description = "IAM role Terragrunt assumes for this account."
  type        = string
}

variable "unit_path" {
  description = "Path of this unit relative to root.hcl."
  type        = string
}

variable "note" {
  description = "Sentence stored with the generated name."
  type        = string
}
