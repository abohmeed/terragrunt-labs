terraform {
  # OpenTofu 1.13 and Terraform 1.17 both fall in this range.
  # Lectures in this section read the binary version line.
  required_version = ">= 1.13.0, < 1.18.0"

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
}
