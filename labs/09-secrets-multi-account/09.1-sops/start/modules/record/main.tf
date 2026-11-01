resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name               = random_pet.name.id
    environment        = var.environment
    note               = var.note
    age_key_configured = tostring(var.age_key_configured)
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker.txt"
  content  = "${null_resource.marker.triggers.name}\n${null_resource.marker.triggers.environment}\n${null_resource.marker.triggers.note}\n${null_resource.marker.triggers.age_key_configured}\n"
}
