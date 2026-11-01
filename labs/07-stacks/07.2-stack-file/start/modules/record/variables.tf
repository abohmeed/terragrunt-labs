variable "environment" {
  description = "Environment name. Set by the unit, not by this module."
  type        = string
}

variable "prefix" {
  description = "Prefix for the generated name. The unit derives this from locals."
  type        = string
}

variable "note" {
  description = "Sentence stored with the generated name."
  type        = string
}
