# Dev stack. One generated unit, with dev values.

unit "record" {
  source = "../../units/record"
  path   = "record"

  values = {
    environment = "dev"
    prefix      = "dev"
    note        = "dev stack"
  }
}
