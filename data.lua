flib = require("__flib__.data-util")
require ("prototypes.entity")
require ("prototypes.event")
require ("prototypes.styles")
flib = nil

data:extend({
  -- custom inputs
  {
    type = "custom-input",
    name = "ltnc-hotkey",
    key_sequence = ""
  }
})
