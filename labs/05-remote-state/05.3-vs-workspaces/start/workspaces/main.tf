locals {
  # TODO: set environment from the selected workspace.
  environment = "TODO"
  note        = "terraform workspace"
}

resource "random_pet" "name" {
  prefix = "${local.environment}-lab"
  length = 2
}

resource "null_resource" "marker" {
  triggers = {
    name        = random_pet.name.id
    environment = local.environment
    note        = local.note
  }

  lifecycle {
    precondition {
      condition     = terraform.workspace != "default"
      error_message = "Create a named workspace before apply. This configuration rejects the default workspace."
    }
  }
}

resource "local_file" "marker" {
  filename = "${path.module}/marker-${terraform.workspace}.txt"
  content  = "${null_resource.marker.triggers.name}\n${local.environment}\n${local.note}\n"
}
