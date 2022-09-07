local M = {}

function M.get_player_data(player_index)
  if global.player_data == nil then
    global.player_data = {}
  end
  local player = game.players[player_index]
  if (player and player.valid) then
    if not global.player_data[player_index] then
      global.player_data[player_index] = {}
    end
    return global.player_data[player_index]
  end
end

function M.format_number(n, append_suffix)
  local amount = tonumber(n)
  if not amount then
    return n
  end
  local suffix = ""
  if append_suffix then
    local suffix_list = {
      ["T"] = 1000000000000,
      ["B"] = 1000000000,
      ["M"] = 1000000,
      ["k"] = 1000
    }
    local floor = math.floor
    local abs = math.abs
    for letter, limit in pairs (suffix_list) do
      if abs(amount) >= limit then
        amount = floor(amount/(limit/10))/10
        suffix = letter
        break
      end
    end
  end
  local formatted = tostring(amount)
  local k
  local gsub = string.gsub
  while true do
    formatted, k = gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k == 0) then
      break
    end
  end
  return formatted..suffix
end

function M.clamp(value, min, max)
  return math.max(min, math.min(max, tonumber(value)))
end

-- Get size of largest cargo-wagon for locked-slots bounding
function M.get_max_wagon_size()
  local entity_filters = {}
  table.insert(entity_filters, {filter = "type", type = "cargo-wagon", mode = "or"})
  table.insert(entity_filters, {filter = "name", name = "ee-infinity-cargo-wagon", invert = "true", mode = "and"})
  local cargo_wagons = game.get_filtered_entity_prototypes(entity_filters)
  local cargo_slots = 0
  for k,v in pairs(cargo_wagons) do
    if v.get_inventory_size(defines.inventory.cargo_wagon) > cargo_slots then
---@diagnostic disable-next-line: cast-local-type
      cargo_slots = v.get_inventory_size(defines.inventory.cargo_wagon)
    end
  end
  return cargo_slots
end

function M.signal_tooltip(name, d)
  local max = d.bounds.max
  if name == "ltn-locked-slots" then
    max = M.get_max_wagon_size()
  end
  return {"",
          {"ltnc-signal-tips."..name},
          {"ltnc-signal-tips.zero-value"},
          {"ltnc-signal-tips.min-max-default",d.bounds.min, max, d.default}}
end

return M
