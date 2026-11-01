# Stand-in for one root module: a network, a database, and an app.
# This file was copied into dev, staging, and prod.

variable "prefix" {
  description = "Short name prefix. Set in terraform.tfvars in this copy."
  type        = string
}

variable "note" {
  description = "Sentence stored with the name. Set in terraform.tfvars in this copy."
  type        = string
}

resource "random_pet" "name" {
  length = 2
  prefix = var.prefix

  keepers = {
    note = var.note
  }
}
