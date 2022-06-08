data:extend({
  {
    type = "bool-setting",
    name = "high-provide-threshold",
    setting_type = "runtime-global",
    order = "ma",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "disable-built-combinators",
    order = "mb",
    setting_type = "runtime-global",
    default_value = false
  },
  {
    type = "bool-setting",
    name = "emit-default-network-id",
    order = "mc",
    setting_type = "runtime-global",
    default_value = "false"
  },
  {
    type = "bool-setting",
    name = "show-all-panels",
    setting_type = "runtime-per-user",
    order = "ua",
    default_value = false
  },
  {
    type = "bool-setting",
    name = "show-net-panel",
    setting_type = "runtime-per-user",
    order = "ub",
    default_value = false
  },
  {
    type = "int-setting",
    name = "slider-max-items",
    setting_type = "runtime-per-user",
    order = "uc",
    default_value = 256,
    minimum_value = 0,
    maximum_value = 2147483647 --prevent overflow
  },
  {
    type = "bool-setting",
    name = "use-stacks",
    setting_type = "runtime-per-user",
    order = "ud",
    default_value = true
  },
  {
    type = "int-setting",
    name = "slider-max-fluid",
    setting_type = "runtime-per-user",
    order = "ue",
    default_value = 500000,
    minimum_value = 0,
    maximum_value = 2147483647 --prevent overflow
  },
  {
    type = "bool-setting",
    name = "negative-signals",
    setting_type = "runtime-per-user",
    order = "uf",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "ltnc-upgradable",
    order = "sa",
    setting_type = "startup",
    default_value = false
  },
})
