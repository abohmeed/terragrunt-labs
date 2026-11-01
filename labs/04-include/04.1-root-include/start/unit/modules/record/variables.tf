variable "course" {
  description = "Course name merged from root.hcl."
  type        = string
}

variable "prefix" {
  description = "Prefix for the generated name. The unit sets this."
  type        = string
}

variable "note" {
  description = "Sentence stored with the generated name. The unit overrides the root value."
  type        = string
}
