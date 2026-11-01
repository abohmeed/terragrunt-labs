variable "environment" {
  description = "Environment name stored on the marker."
  type        = string
}

variable "prefix" {
  description = "Prefix for the generated name."
  type        = string
}

variable "note" {
  description = "Sentence stored with the generated name. The value fail is rejected so the error hook has a plan to catch."
  type        = string

  validation {
    condition     = var.note != "fail"
    error_message = "deliberate plan failure"
  }
}
