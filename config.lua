local config = {}

config.ltnc_item_slot_count = 28
config.ltnc_ltn_slot_count  = 14
config.ltnc_misc_slot_count = 14

config.ltn_signals = {
  ["ltn-network-id"]                = {stop_type = "network", default = -1, slot = 1, bounds = {min = -2^31, max = 2^31 - 1}},
  ["ltn-min-train-length"]          = {stop_type = "common", default = 0, slot = 2, bounds = {min = 0, max = 1000}},
  ["ltn-max-train-length"]          = {stop_type = "common", default = 0, slot = 3, bounds = {min = 0, max = 1000}},
  ["ltn-max-trains"]                = {stop_type = "common", default = 0, slot = 4, bounds = {min = 0, max = 1000}},
  ["ltn-requester-threshold"]       = {stop_type = "requester", default = 1000, slot = 5, bounds = {min = -2000000000, max = 2000000000}},
  ["ltn-requester-stack-threshold"] = {stop_type = "requester", default = 0, slot = 6, bounds = {min = -2000000000, max = 2000000000}},
  ["ltn-requester-priority"]        = {stop_type = "requester", default = 0, slot = 7, bounds = {min = -2000000000, max = 2000000000}},
  ["ltn-disable-warnings"]          = {stop_type = "requester", default = 0, slot = 8, bounds = {min = 0, max = 1}},
  ["ltn-provider-threshold"]        = {stop_type = "provider", default = 1000, slot = 9, bounds = {min = 0, max = 2000000000}},
  ["ltn-provider-stack-threshold"]  = {stop_type = "provider", default = 0, slot = 10, bounds = {min = 0, max = 2000000000}},
  ["ltn-provider-priority"]         = {stop_type = "provider", default = 0, slot = 11, bounds = {min = -2000000000, max = 2000000000}},
  ["ltn-locked-slots"]              = {stop_type = "provider", default = 0, slot = 12, bounds = {min = 0, max = 40}},
  ["ltn-depot"]                     = {stop_type = "depot", default = 0, slot = 13, bounds = {min = 0, max = 1}},
  ["ltn-depot-priority"]            = {stop_type = "depot", default = 0, slot = 14, bounds = {min = -2000000000, max = 2000000000}},
}

config.LTN_STOP_NONE      = 0
config.LTN_STOP_DEPOT     = 1
config.LTN_STOP_REQUESTER = 2
config.LTN_STOP_PROVIDER  = 4

config.LTN_STOP_DEFAULT = config.LTN_STOP_PROVIDER

config.high_threshold_count = 50000000

return config
