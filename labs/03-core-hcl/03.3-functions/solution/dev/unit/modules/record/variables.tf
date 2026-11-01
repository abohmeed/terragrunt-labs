variable "course" {
  description = "Course name read from root.hcl."
  type        = string
}

variable "region" {
  description = "Region read from region.hcl. Offline labs use local."
  type        = string
}

variable "environment" {
  description = "Environment read from env.hcl."
  type        = string
}

variable "prefix" {
  description = "Prefix derived from the environment, region, and env.hcl."
  type        = string
}

variable "unit_path" {
  description = "Path of this unit relative to root.hcl."
  type        = string
}

variable "note" {
  description = "Sentence from LAB_NOTE, or the default when that variable is unset."
  type        = string
}
