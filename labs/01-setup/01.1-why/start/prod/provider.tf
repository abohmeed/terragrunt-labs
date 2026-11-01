# Drift: dev moved to Terraform 1.17 and random 3.6. This copy was not updated.
terraform {
  required_version = ">= 1.6.0, < 1.7.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}
