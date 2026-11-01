variable "course" {
  description = "Course name merged from root.hcl."
  type        = string
}

variable "prefix" {
  description = "Prefix for the generated name. Each unit sets its own."
  type        = string
}

variable "note" {
  description = "Sentence stored with the generated name."
  type        = string
}

variable "tags" {
  description = "Tags from root.hcl and the unit. The merge strategy decides which keys remain."
  type        = map(string)
}

variable "labels" {
  description = "Labels from root.hcl and the unit. Shallow replaces the list. Deep concatenates it."
  type        = list(string)
}
