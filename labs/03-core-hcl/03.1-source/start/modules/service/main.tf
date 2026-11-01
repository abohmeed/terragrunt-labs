module "label" {
  # TODO: point this at the sibling module, ../label.
  # The path is relative to this file. It resolves after Terragrunt copies
  # the module tree into .terragrunt-cache.
  source = "../TODO"

  prefix = var.prefix
  note   = var.note
}
