MOD_STRING  = "LTN Combinator"

print, dlog = require "script.logger" ()
require("config")
require("script.util")
local ltnc = require("script.gui")


-- TODO: Remote commands
-- register remote interfaces
remote.add_interface("ltn-combinator", {
  -- Usage: result = remote.call("ltn-combinator", "open_ltn_combinator", player_index (integer), entity (LuaEntity), register (boolean))
  --  player_index: (required)
  --  entity: any entity that is in the same green-circuit-network as the wanted ltn-combinator (required)
  --  register: registers the opened window in game.player[i].opened (optional, default true)
  --  returns a boolean, whether a combinator was opened
  open_ltn_combinator = ltnc.open_combinator,
  
  -- Usage: result = remote.call("ltn-combinator", "close_ltn_combinator", player_index (integer))
  --  player_index: (required)
  --
  --  Calling this interface is only required if a ltn-combinator was previously opened with register = false.
  --  Use this method to keep your own window open.
  close_ltn_combinator = ltnc.close_combinator
})

-- debugging tool for remote call testing
local function ltnc_remote_open(event)
  local entity = nil
  if game.players[event.player_index] then
    entity = game.players[event.player_index].selected
  end
  
  if entity == nil or entity.valid ~= true then return end 
  remote.call("ltn-combinator", "open_ltn_combinator", event.player_index, entity, true)
end

local function ltnc_remote_close(event)
  remote.call("ltn-combinator", "close_ltn_combinator", event.player_index)
end

commands.add_command("ltncopen", "Use /ltncopen while hovering an entity to open a near ltn combinator", ltnc_remote_open)
commands.add_command("ltncclose", "Use /ltncclose to close the opened ltn combinator", ltnc_remote_close)
--commands.add_command("ltncconfig", "Use /ltncconfig to setup network icons", ltnc_open_network)

-- TODO: Move mod / settings init here

--[[
local function player_joined(player_index)
  get_player_data(player_index)
end

event.register({defines.events.on_player_created}, function(e)
  player_joined(e.plyaer_index)
end
)
]]