resource "random_pet" "name" {
  length = 2
  prefix = var.prefix

  keepers = {
    note = var.note
  }
}
