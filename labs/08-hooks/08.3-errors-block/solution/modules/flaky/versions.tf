terraform {
  required_version = ">= 1.17.0, < 1.18.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
