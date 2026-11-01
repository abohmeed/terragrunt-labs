# Environment values for units under dev/. A prod directory would carry its own env.hcl.
# This file is not a unit.

locals {
  environment = "dev"
  prefix_root = "lab"
}
