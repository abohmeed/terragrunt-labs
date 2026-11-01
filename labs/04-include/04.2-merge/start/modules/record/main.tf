resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name        = random_pet.name.id
    course      = var.course
    note        = var.note
    owner       = lookup(var.tags, "owner", "")
    tier        = var.tags["tier"]
    cost_center = lookup(var.tags, "cost_center", "")
    labels      = join(",", var.labels)
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker.txt"
  content  = "${null_resource.marker.triggers.name}\n${null_resource.marker.triggers.course}\n${null_resource.marker.triggers.note}\n${null_resource.marker.triggers.owner}\n${null_resource.marker.triggers.tier}\n${null_resource.marker.triggers.cost_center}\n${null_resource.marker.triggers.labels}\n"
}
