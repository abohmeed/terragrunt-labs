variable "attempt_file" {
  description = "Counter file outside .terragrunt-cache. A retry keeps this file and drops the module copy."
  type        = string
}
