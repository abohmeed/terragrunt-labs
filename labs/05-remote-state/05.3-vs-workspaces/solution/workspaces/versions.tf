terraform {
  required_version = ">= 1.17.0, < 1.18.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # path is the default workspace file. Named workspaces land in
  # terraform.tfstate.d/<name>/ next to this directory.
  backend "local" {
    path = "../state/workspaces/terraform.tfstate"
  }
}
