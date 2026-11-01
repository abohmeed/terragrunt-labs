# Prod stack. Same unit as dev. The values are the prod override.

unit "record" {
  source = "../../units/record"
  path   = "record"

  values = {
    environment = "prod"
    prefix      = "prd"
    note        = "prod stack"
  }
}
