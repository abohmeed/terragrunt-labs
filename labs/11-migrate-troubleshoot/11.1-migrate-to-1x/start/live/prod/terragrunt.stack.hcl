# Prod stack. Point source at the shared unit and keep the values below.

unit "record" {
  source = "TODO"
  path   = "record"

  values = {
    environment = "prod"
    prefix      = "prd"
    note        = "prod stack"
  }
}
