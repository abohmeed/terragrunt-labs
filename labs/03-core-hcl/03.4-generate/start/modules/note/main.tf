resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name = random_pet.name.id
    note = var.note
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker.txt"
  content  = "${null_resource.marker.triggers.name}\n${var.note}\n"
}
