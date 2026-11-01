resource "random_pet" "name" {
  prefix = var.account_name
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name         = random_pet.name.id
    account_name = var.account_name
    account_id   = var.account_id
    aws_region   = var.aws_region
    role_arn     = var.role_arn
    unit_path    = var.unit_path
    note         = var.note
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker.txt"
  content  = "${null_resource.marker.triggers.name}\n${null_resource.marker.triggers.account_name}\n${null_resource.marker.triggers.account_id}\n${null_resource.marker.triggers.aws_region}\n${null_resource.marker.triggers.role_arn}\n${null_resource.marker.triggers.unit_path}\n${null_resource.marker.triggers.note}\n"
}
