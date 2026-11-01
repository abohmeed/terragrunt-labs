# plain is finished. It has no values attribute, so the unit default stands.
# Fill network and service, and wire service to the network output.

unit "plain" {
  source = "../units/record"
  path   = "plain"
}

unit "network" {
  source = "../units/record"
  path   = "network"

  values = {
    environment = "TODO"
    prefix      = "TODO"
    note        = "TODO"
  }
}

unit "service" {
  source = "../units/record"
  path   = "service"

  values = {
    environment = "TODO"
    prefix      = "TODO"
    note        = "TODO"
  }
}
