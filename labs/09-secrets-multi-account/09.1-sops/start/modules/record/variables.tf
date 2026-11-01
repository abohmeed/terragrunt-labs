variable "environment" {
  description = "Environment name. Set by the unit, not by this module."
  type        = string
}

variable "prefix" {
  description = "Prefix for the generated name."
  type        = string
}

variable "note" {
  description = "Sentence decrypted from the SOPS file."
  type        = string
}

variable "db_password" {
  description = "Lab fixture decrypted from the SOPS file. It is not a real credential."
  type        = string
  sensitive   = true
}

variable "age_key_configured" {
  description = "True when SOPS_AGE_KEY_FILE is set to a non-empty path."
  type        = bool
}
