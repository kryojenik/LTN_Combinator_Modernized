local config = require("__LTN_Combinator_Modernized__/script/config")
local global_data = require("__LTN_Combinator_Modernized__/script/global_data")
local player_data = require("__LTN_Combinator_Modernized__/script/player_data")

local old_global = global or {}

local old_high_threshold = 50000000

global = {}
global_data.init()

for _, player in pairs(game.players) do
  for _, gui in pairs({ player.gui.top, player.gui.left, player.gui.center, player.gui.screen, player.gui.relative }) do
    for _, child in pairs(gui.children) do
      if child.get_mod() == "LTN_Combinator_Modernized" then
        child.destroy()
      end
    end
  end
  player_data.init(player)
end

-- Find all the combinators and create an entry in global
local combinator_count = 0
for _, surface in pairs(game.surfaces) do
  local entities = surface.find_entities_filtered({name = "ltn-combinator"})
  if not string.match(surface.name, "^secret") then
    combinator_count = combinator_count + #entities
  end
  for _, entity in pairs(entities) do
    local cd = { provider = true, requester = true}
    local ctl = entity.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
    -- Set the requester and provider states based on signals set on the combinator.
    -- If depot is set, all provider and requester signals are ignored.
    -- Disable requester and provider
    local sig = ctl.get_signal(config.ltn_signals["ltn-depot"].slot)
    if sig.signal and sig.signal.name == "ltn-depot" and sig.count > 0 then
      cd = { provider = false, requster = false }
    end
    
    -- Check the requester and provider thresholds.  If the are greater than the old value
    -- used to disble the service, fix the value and make sure the service is disabled.
    for _, service in ipairs{ "provider", "requester" } do
      local name = "ltn-" .. service .. "-threshold"
      local stack_name = "ltn-" .. service .. "-stack-threshold"
      sig = ctl.get_signal(config.ltn_signals[name].slot)
      -- If threshold is above <old_high_threshold> set the service to off
      -- and set the new high threshold, remove the stack threshold
      if sig.signal and sig.signal.name == name and sig.count >= old_high_threshold then
        cd[service] = false
        ctl.set_signal(config.ltn_signals[name].slot, {
          signal = { name = name, type = "virtual" },
          count = config.high_threshold
        })
        ctl.set_signal(config.ltn_signals[stack_name].slot, nil)
      end
    end

    global.combinators[entity.unit_number] = cd
  end
end
if combinator_count > 0 then
  game.print({"ltnc.migrated-combinators", combinator_count})
end

-- Migrate any network descriptions and icons
if old_global.network_description then
  for net, details in pairs(old_global.network_description) do
    if not details.tip and not details.icon then
      goto continue
    end
    global.network_descriptions[net] = {}
    global.network_descriptions[net].tip = details.tip
    if details.icon then
      global.network_descriptions[net].icon = details.icon.type .. "/" .. details.icon.name
    end
    ::continue::
  end
end