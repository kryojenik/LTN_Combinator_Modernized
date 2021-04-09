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
        type = "bool-setting",
        name = "ltnc-upgradable",
        order = "sa",
        setting_type = "startup",
        default_value = false
    },
})