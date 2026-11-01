# Copied with the root module.
# The backend block cannot use variables, so the state path is a hard-coded
# key for this copy. An S3 backend has the same limit: bucket and key are literals.
terraform {
  backend "local" {
    path = "prod/terraform.tfstate"
  }
}
