resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name        = random_pet.name.id
    course      = var.course
    region      = var.region
    environment = var.environment
    unit_path   = var.unit_path
    note        = var.note
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker.txt"
  content  = "${null_resource.marker.triggers.name}\n${null_resource.marker.triggers.course}\n${null_resource.marker.triggers.region}\n${null_resource.marker.triggers.environment}\n${null_resource.marker.triggers.unit_path}\n${null_resource.marker.triggers.note}\n"
}
