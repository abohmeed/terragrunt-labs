# Stack. This directory has no terragrunt.hcl, so it is not a unit.
# terragrunt stack generate writes the unit under .terragrunt-stack/.

unit "record" {
  source = "../units/record"
  path   = "record"
}
