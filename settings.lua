data:extend({
  {
    type = "bool-setting",
    name = "ltnc-high-provide-threshold",
    setting_type = "runtime-global",
    order = "ma",
    default_value = true
  },
  {
    type = "string-setting",
    name = "ltnc-disable-built-combinators",
    order = "mc",
    setting_type = "runtime-global",
    default_value = "requester-only",
    allowed_values = {"none", "requester-only", "all"}
  },
  {
    type = "bool-setting",
    name = "ltnc-emit-default-network-id",
    order = "me",
    setting_type = "runtime-global",
    default_value = "false"
  },
  {
    type = "bool-setting",
    name = "ltnc-show-all-panels",
    setting_type = "runtime-per-user",
    order = "ua",
    default_value = false
  },
  {
    type = "bool-setting",
    name = "ltnc-show-net-panel",
    setting_type = "runtime-per-user",
    order = "ub",
    default_value = false
  },
  {
    type = "int-setting",
    name = "ltnc-slider-max-items",
    setting_type = "runtime-per-user",
    order = "uc",
    default_value = 256,
    minimum_value = 0,
    maximum_value = 2147483647 --prevent overflow
  },
  {
    type = "bool-setting",
    name = "ltnc-use-stacks",
    setting_type = "runtime-per-user",
    order = "ud",
    default_value = true
  },
  {
    type = "int-setting",
    name = "ltnc-slider-max-fluid",
    setting_type = "runtime-per-user",
    order = "ue",
    default_value = 500000,
    minimum_value = 0,
    maximum_value = 2147483647 --prevent overflow
  },
  {
    type = "bool-setting",
    name = "ltnc-negative-signals",
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
  {
    type = "int-setting",
    name = "ltnc-signal-rows",
    order = "sb",
    setting_type = "startup",
    default_value = 2,
    allowed_values = {1,2,3,4,5,6,7,8,9,10}
  },
})
