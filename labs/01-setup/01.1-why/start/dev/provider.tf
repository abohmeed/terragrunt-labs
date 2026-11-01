# Updated copy. Staging and prod were not kept in step with this file.
terraform {
  required_version = ">= 1.17.0, < 1.18.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
