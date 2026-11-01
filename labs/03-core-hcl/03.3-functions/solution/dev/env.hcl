# Environment values for units under dev/. A prod directory would carry its own env.hcl.

locals {
  environment = "dev"
  prefix_root = "lab"
}
