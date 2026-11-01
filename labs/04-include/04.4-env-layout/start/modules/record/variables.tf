variable "course" {
  description = "Course name read from the exposed root include."
  type        = string
}

variable "account" {
  description = "Account name read from the exposed account include."
  type        = string
}

variable "region" {
  description = "Region read from the exposed region include. Offline labs use local."
  type        = string
}

variable "environment" {
  description = "Environment read from the exposed env include."
  type        = string
}

variable "prefix" {
  description = "Prefix derived from the account, environment, and env.hcl."
  type        = string
}

variable "unit_path" {
  description = "Path of this unit relative to root.hcl."
  type        = string
}
