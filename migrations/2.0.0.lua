local global_data = require("__LTN_Combinator_Modernized__/script/global_data")
local player_data = require("__LTN_Combinator_Modernized__/script/player_data")

local old_global = global or {}

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