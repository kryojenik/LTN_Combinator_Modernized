local math = require("__flib__/math")

local config = require("__LTN_Combinator_Modernized__/script/config")

local M = {}

-- Needed a variable to hide a nil param from the language server :/
---@type Signal
M.nilSignal = nil

---Set slider value and stacks textbox value from the items text box
---@param player LuaPlayer
function M.from_items(player)
  local ws = global.players[player.index].working_slot
  local value = tonumber(ws.items.text) --[[@as number]]
  if not value then
    return
  end

  ws.stacks.text = tostring(value / ws.stack_size)
  ws.slider.slider_value = math.abs(value)
end -- M.from_items()

---Set slider value and stacks textbox value from the items text box
---@param player LuaPlayer
function M.from_stacks(player)
  local ws = global.players[player.index].working_slot
  local value = tonumber(ws.stacks.text)
  if not value then
    return
  end

  value = math.clamp(value * ws.stack_size, math.min_int, math.max_int)
  value = value < 0 and math.ceiled(value, ws.stack_size) or  math.floored(value, ws.stack_size)
  ws.items.text = tostring(value)
  ws.slider.slider_value = math.abs(value)
end -- M.from_stacks()

---Set slider value and stacks textbox value from the items text box
---@param player LuaPlayer
function M.from_slider(player)
  local ws = global.players[player.index].working_slot
  local value = ws.slider.slider_value
  ws.stacks.text = tostring(value / ws.stack_size)
  ws.items.text = tostring(value)
end --M.from_slider()

---Encode the Network ID from the buttons that are enabled
---@param player LuaPlayer @ Player operating the combinator
function M.from_netid_buttons(player)
  local pt = global.players[player.index]
  local netid_textbox = pt.main_elems["text_entry__ltn-network-id"]
  local netid_buttons = pt.main_elems.net_encode_table
  local netid = 0
  for i = 1, 31 do
    if netid_buttons.children[i].style.name == "ltnc_net_id_button_pressed" then
      netid = netid + 2^(i-1)
    end
  end
  if netid_buttons.children[32].style.name == "ltnc_net_id_button_pressed" then
    netid = netid - 2^(31)
  end
  netid_textbox.text = tostring(netid)
end -- M.from_netid_buttons()

---Check if the entered value is within bounds
---@param name LTNSignals
---@param value number? @ Value attempting to write to combinator.  nil is valid
---@return boolean @ True if valid setting for the combinator
function M.is_valid(name, value)
  if not value then return true end
  local signal = config.ltn_signals[name]
  return value >= signal.min and value <= signal.max
end

--- @param e EventData.on_player_setup_blueprint
--- @return LuaItemStack?
function M.get_blueprint(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local bp = player.blueprint_to_setup
  if bp and bp.valid_for_read then
    return bp
  end

  bp = player.cursor_stack
  if not bp or not bp.valid_for_read then
    return
  end

  if bp.type == "blueprint-book" then
    local item_inventory = bp.get_inventory(defines.inventory.item_main)
    if item_inventory then
      bp = item_inventory[bp.active_index]
    else
      return
    end
  end

  return bp
end

  --- Recursive function to find combinator up to <max_depth> connections away
  --- @param find_name string # The entity to look for
  --- @param start_list table<uint, LuaEntity> # List of entities to start search from
  --- @param max_depth uint # Max number of connections away to search (Poles are a connection)
  --- @return LuaEntity?
function M.find_connected_entity(find_name, start_list, max_depth)
  local seen = {}
  local walk_entities
  walk_entities = function(name, entity_list, depth)
    local next_entity_list = {}
    for unit, e in pairs(entity_list) do
      if e.name == name then
        -- We've found the closest entity <name>
        return e
      end

      -- Mark this entity as processed so we don't process it again.
      -- This it is seen on the next entity or if there are loops in the circuit network
      seen[unit] = true
      if not e.circuit_connected_entities then
        return
      end

      -- Outer loop get are the possible wire connections (red / green)
      for _, connected_entities in pairs(e.circuit_connected_entities) do
        --- @cast connected_entities LuaEntity[]
        -- Inner loop works through all the adjacent entities on a network.
        for _, connected_entity in ipairs(connected_entities) do
          if not seen[connected_entity.unit_number] then
            next_entity_list[connected_entity.unit_number] = connected_entity
          end
        end
      end
    end

    if depth == max_depth then
      -- Reached the maximum depth and did't find an LTN combinator.
      return
    end

    -- If there are more un-seen entities another connection away, recurse
    if next(next_entity_list) then
      return walk_entities(name, next_entity_list, depth + 1)
    end
  end

  return walk_entities(find_name, start_list, 0)
end

return M