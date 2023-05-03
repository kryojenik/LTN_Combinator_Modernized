local flib_gui = require("__flib__/gui-lite")
local table = require("__flib__/table")
local flib_format = require("__flib__/format")
local flib_position = require("__flib__/position")

local util = require("__LTN_Combinator_Modernized__/script/util")
local netui = require("__LTN_Combinator_Modernized__/script/network_descriptions")
local global_data = require("__LTN_Combinator_Modernized__/script/global_data")
local player_data = require("__LTN_Combinator_Modernized__/script/player_data")

local config = require("__LTN_Combinator_Modernized__/script/config")

--- @enum ToggleType
local tt = {
  bits = 1,
  on = 2,
  off = 3
}

--- Get the combinator data from global.  Create it if it doesn't exist
---@param unit_number uint
---@return CombinatorData
local function get_combinator_data(unit_number)
  if not global.combinators[unit_number] then
    global.combinators[unit_number] = {}
  end
  return global.combinators[unit_number]
end

--- Retreive an LTN signal from specified entity 
--- If it is not set, return the default value
--- @param ltn_signal_name LTNSignals @ The signal name being retreived
--- @param ctl LuaConstantCombinatorControlBehavior
--- @return {value: integer, is_default: boolean}
local function get_ltn_signal_from_control(ctl, ltn_signal_name)
  local slot = config.ltn_signals[ltn_signal_name].slot
  local default = config.ltn_signals[ltn_signal_name].default
  local signal = ctl.get_signal(slot)
  if signal.signal then
    return { value = signal.count, is_defualt = false }
  else
    return { value = default, is_default = true }
  end
end -- get_ltn_signal_from_control()

--- Retreive an LTN signal from combinator representd by this table 
--- If it is not set, return the default value
--- @param ltn_signal_name LTNSignals @ The signal name being retreived
--- @param self LTNC
--- @return {value: integer, is_default: boolean}
local function get_ltn_signal(self, ltn_signal_name)
  local ctl = self.control
  return get_ltn_signal_from_control(ctl, ltn_signal_name)
end -- get_ltn_signal

--- @param ctl LuaConstantCombinatorControlBehavior
local function is_depot(ctl)
  return get_ltn_signal_from_control(ctl, "ltn-depot").value > 0 and true or false
end

--- Enable or disable the edit elements in the provider / requester sections.
---@param self LTNC
---@param set_enable boolean
local function toggle_ui_req_prov_panels(self, set_enable)
  local services = { "provider", "requester" }
  for _, service in ipairs(services) do
    for _, elem in ipairs(self.elems["table_" .. service].children) do
      elem.enabled = set_enable
    end

    -- Set the provider and requester states to false in global data
    local chkbox = self.elems["check__" .. service]
    chkbox.enabled =set_enable
  end
end

local function update_ui_network_id_label(self, netid)
  local label = self.elems["label__ltn-network-id"]
  label.caption = { "ltnc.encode-net-id", flib_format.number(netid, false) }
end

--- Parse the Network ID and populate the bitfield editor
--- @param self LTNC
--- @param type ToggleType? @ How should buttons be updated?
local function update_ui_network_id_buttons(self, type)
  type = type or tt.bits
  local gni = global.network_descriptions
  local btns = self.elems.net_encode_table.children
  local netid = get_ltn_signal(self, "ltn-network-id").value
  update_ui_network_id_label(self, netid)
  for i = 1, 32 do
    if type == tt.bits then
      local bit = 2 ^ (i - 1)
      btns[i].tooltip = { "ltnc.net-description-tip" }
      btns[i].sprite = nil
      btns[i].caption = tostring(i)
      btns[i].style = bit32.btest(netid, bit) and "ltnc_net_id_button_pressed" or "ltnc_net_id_button"
    else
      btns[i].style = type == tt.on and "ltnc_net_id_button_pressed" or "ltnc_net_id_button"
    end
    if gni[i] then
      if gni[i].icon then
        btns[i].sprite = gni[i].icon
        btns[i].caption = ""
      end
      if gni[i].tip then
        btns[i].tooltip = { "", gni[i].tip, "\n\n", { "ltnc.net-description-tip" } }
      end
    end
  end
end -- update_ui_network_id_buttons()

--- Populate a specific LTN Signal in the UI
--- @param ltn_signal_name LTNSignals @ LTN Signal to populate
--- @param self LTNC
local function update_ui_ltn_signal(self, ltn_signal_name)
  local elem = self.elems["text_entry__" .. ltn_signal_name]
  local ret = get_ltn_signal(self, ltn_signal_name)

  if ltn_signal_name == "ltn-depot" or ltn_signal_name == "ltn-disable-warnings" then
    elem = self.elems["check__" .. ltn_signal_name]
    elem.state = ret.value > 0 and true or false
  else
    elem.style = "ltnc_entry_text"
    if string.match(ltn_signal_name, "%-threshold$") then
      local cd = get_combinator_data(self.entity.unit_number)
      local req_prov = string.match(ltn_signal_name, "ltn%-(.-)%-")
      if not cd[req_prov] then
        elem.style = "ltnc_entry_text_not_transmitted"
        ret.value = cd[ltn_signal_name] and cd[ltn_signal_name] or config.ltn_signals[ltn_signal_name].default
        ret.is_default = false
      end
    end

    if ret.is_default then
      elem.style = "ltnc_entry_text_default_value"
    end

    elem.text = tostring(ret.value)
    if ltn_signal_name == "ltn-network-id" then
      update_ui_network_id_label(self, ret.value)
    end
  end
end -- update_ltn_signal()

--- Populate the LTN signals into their respecitve UI elements
--- @param self LTNC
local function update_ui_all_ltn_signals(self)
  for ltn_signal, _ in pairs(config.ltn_signals) do
    update_ui_ltn_signal(self, ltn_signal)
  end
end -- update_ltn_signals()

-- Checks if request/provide is enabled and returns the approriate value to set on the combinator
--- @param unit_number uint Entity unit number
--- @param name LTNSignals LTN Threshold Signal name
--- @param value integer Real threshold to store in global
--- @return integer # Threshold to apply to combinator dependant on request/provide state
local function check_threshold(unit_number, value, name)
  local cd = get_combinator_data(unit_number)
  if (string.match(name, "ltn%-requester") and cd.requester)
  or (string.match(name, "ltn%-provider") and cd.provider) then
    return value
  end
  
  if (string.match(name,"stack")) then
    return 0
  else
    return config.high_threshold
  end
end -- check_threshold()

--- @param value integer
--- @param ltn_signal_name LTNSignals
--- @param ctl LuaConstantCombinatorControlBehavior
local function set_ltn_signal_by_control(ctl, value, ltn_signal_name)
  local settings = settings.global
  local explicit_network = settings["ltnc-emit-default-network-id"].value
  local explicit_default = settings["ltnc-emit-explicit-default"].value
  local ltn_signals = config.ltn_signals


  -- Need to store thresholds in global and set the correct values on the combinator
  -- dependant on provider/requester states
  if string.match(ltn_signal_name, "%-threshold$") then
    local cd = get_combinator_data(ctl.entity.unit_number)
    cd[ltn_signal_name] = value ~= 0 and value or nil
    if not is_depot(ctl) then
      value = check_threshold(ctl.entity.unit_number, value, ltn_signal_name)
    end
  end

  -- Remove the signal if it is zero or non-existant
  if not value or value == 0 then
    ctl.set_signal(config.ltn_signals[ltn_signal_name].slot, util.nilSignal)
    return
  end

  --- @type Signal
  local signal = {}
  signal.count = value
  signal.signal = { name = ltn_signal_name, type = "virtual" }
  
  -- Set the non-default values
  if signal.count ~= ltn_signals[ltn_signal_name].default then
    ctl.set_signal(config.ltn_signals[ltn_signal_name].slot, signal)
    return
  end

  -- Handle setting default values.  Map setting control if values are stored when default
  -- Otherwise, default values are removed.
  if (ltn_signal_name == "ltn-network-id" and explicit_network)
      or (ltn_signal_name ~= "ltn-network-id" and explicit_default) then
    ctl.set_signal(ltn_signals[ltn_signal_name].slot, signal)
  else
    ctl.set_signal(config.ltn_signals[ltn_signal_name].slot, util.nilSignal)
  end
end -- set_ltn_signal_by_control()

local function set_ltn_signal(self, value, ltn_signal_name)
  set_ltn_signal_by_control(self.control, value, ltn_signal_name)
end -- set_ltn_signal()

--- Retreive a miscelaneous signal from the combinator
--- @param slot uint @ The slot to get data from
--- @param self LTNC
--- @return Signal
local function get_misc_signal(self, slot)
  local ctl = self.control
  return ctl.get_signal(slot + config.ltnc_ltn_signal_count)
end -- get_misc_signal()

--- @param self LTNC
local function reset_ui_misc_signal_contols(self)
  local pt = global.players[self.player.index]
  local ws = pt.working_slot
  if not ws then
    return
  end
  
  ws.slider.enabled = false
  ws.stacks.enabled = false
  ws.items.enabled = false
  ws.confirm.enabled = false
  ws.cancel.enabled = false
  
  pt.working_slot = nil
end -- reset_misc_signal_contols()

--- Populate a specific miscelaneous signal slot
--- @param slot uint
--- @param self LTNC
local function update_ui_misc_signal(self, slot)
  local ctl = self.control
  local ret = ctl.get_signal(slot + config.ltnc_ltn_signal_count)
  local button = self.elems["misc_signal_slot__" .. slot]
  local value = button.children[1]
  if ret.signal then
    value.caption = flib_format.number(ret.count, true)
    button.elem_value = ret.signal
    button.locked = true
  else
    value.caption = ""
    button.elem_value = nil
    button.locked = false
  end
end -- update_misc_signal()

--- Populate the miscelaneous signal table
--- @param self LTNC
local function update_ui_all_misc_signals(self)
  --- @type uint
  for i = 1, config.ltnc_misc_signal_count do
    update_ui_misc_signal(self, i)
  end
end -- update_misc_signal()

--- Set up the UI to set a misc signal value
--- @param slot uint
--- @param self LTNC
local function open_ui_misc_signal_edit_controls(self, slot)
  local pt = global.players[self.player.index]
  local ws = pt.working_slot
  if ws and ws.index ~= slot then
    update_ui_misc_signal(self, ws.index)
    pt.working_slot = nil
  end

  local cur = get_misc_signal(self, slot)
  if not cur then
    return
  end

  if not cur.signal then
    -- Must be setting up a new signal slot
    cur.signal = {}
    local elem = self.elems["misc_signal_slot__" .. slot]
    cur.signal.name = elem.elem_value.name
    cur.signal.type = elem.elem_value.type
  end

  -- Record the slot player is working with in global so that values can be
  -- updated with later events
  ws = {}
  pt.working_slot = ws
  local slider_max
  local slider_increment

  ws.index = slot
  ws.panel = self.elems.stack_item_flow
  ws.slider = self.elems.misc_signal_slider
  ws.stacks = self.elems.text_entry__stacks
  ws.items = self.elems.text_entry__item_fluid
  ws.confirm = self.elems.signal_quantity_confirm
  ws.cancel = self.elems.signal_quantity_cancel

  ws.slider.enabled = true
  ws.stacks.enabled = true
  ws.items.enabled = true
  ws.confirm.enabled = true
  ws.cancel.enabled = true

  if cur.signal.type == "item" then
    ws.stack_size = game.item_prototypes[cur.signal.name].stack_size
    ws.stacks.enabled = true
    slider_max = config.slider_max_stacks * ws.stack_size
    slider_increment = ws.stack_size
  else
    ws.stack_size = 1 --fluids and virtuals don't have stacks
    ws.stacks.enabled = false
    -- TODO: Base on user setting on multiples of chosen tank type?
    slider_max = config.slider_max_fluid
    slider_increment = 1000
  end
  ws.items.text = tostring(cur.count)
  ws.slider.set_slider_minimum_maximum(0, slider_max)
  ws.slider.set_slider_value_step(slider_increment)
  util.from_items(self.player)

  if cur.signal.type == "item" and pt.settings["ltnc-use-stacks"] then
    ws.stacks.enabled = true
    ws.stacks.focus()
    ws.stacks.select_all()
  else
    ws.stacks.enabled = false
    ws.items.focus()
    ws.items.select_all()
  end
end -- open_misc_signal_edit_controls()

--- Clear a miscelaneous signal slot
--- @param slot uint
--- @param self LTNC
local function clear_misc_signal(self, slot)
  local ctl = self.control
  ctl.set_signal(slot + config.ltnc_ltn_signal_count, util.nilSignal)
end -- clear_misc_signal()

--- @param signal Signal
--- @param slot uint
--- @param self LTNC
local function set_misc_signal(self, signal, slot)
  local ctl = self.control
  ctl.set_signal(slot, signal)
end -- set_misc_signal()

--- Refresh the entire UI with current data
--- @param self LTNC
local function update_ui(self)
  -- update enabled / disables status
  if not self.entity.valid then
    return
  end
  if self.control.enabled then
    -- Enabled
    self.elems.on_off.switch_state = "right"
    self.elems.status_indicator.sprite = "flib_indicator_green"
    self.elems.status_label.caption = { "ltnc.status-working" }
  else
    -- Disabled
    self.elems.on_off.switch_state = "left"
    self.elems.status_indicator.sprite = "flib_indicator_red"
    self.elems.status_label.caption = { "ltnc.status-disabled" }
  end
  -- update LTN signals
  update_ui_all_ltn_signals(self)
  update_ui_network_id_buttons(self)
  -- update Misc signals
  update_ui_all_misc_signals(self)
  -- TODO: update provider / requester / depot state
  local cd = get_combinator_data(self.entity.unit_number)
  self.elems.check__provider.state = cd.provider
  self.elems.check__requester.state = cd.requester
  if is_depot(self.control) then
    toggle_ui_req_prov_panels(self, false)
  end
end -- update_ui()

--- Sort the signals within the combinator.
--- @param self LTNC | LuaEntity
local function sort_signals(self)
  local needs_sorting = false
  local ctl = self.control or self.get_control_behavior()

  -- Validate signal slot locations, If sorting is not needed skip it.
  --- @type uint
  for i = 1, ctl.signals_count do
    local signal = ctl.get_signal(i)
    if signal.signal ~= nil then
      local name = signal.signal.name
      local type = signal.signal.type

      -- If LTN Signal, make sure it's in the proper slot.
      if type == "virtual" and config.ltn_signals[name] ~= nil then
        -- Signals with a value of 0 are not emitted on the wire.
        -- In the case of an LTN, absence of a control signal will result in the LTN default
        -- being used.  Remove LTN signals with a vaule of 0 to remove ambiguity.
        if signal.count == 0 then
          ctl.set_signal(i, util.nilSignal)
        else
          needs_sorting = config.ltn_signals[name].slot ~= i or i > config.ltnc_ltn_signal_count --or needs_sorting
        end
      else
        -- If it is not an LTN Signal, make sure its not in an LTN slot.
        needs_sorting = i <= config.ltnc_ltn_signal_count --or needs_sorting
      end
    end
    -- No need to check all the signals if we found one requring sorting.
    if needs_sorting then break end
  end

  --Sort the signals if needed.
  if needs_sorting then
    local temp_signals = {}
    --- @type uint
    for j = 1, ctl.signals_count do
      local signal = ctl.get_signal(j)
      if signal.signal ~= nil then
        table.insert(temp_signals, signal)
        ctl.set_signal(j, util.nilSignal)
      end
    end
    --- @type uint
    local misc_slot = config.ltnc_ltn_signal_count + 1
    for _, s in pairs(temp_signals) do
      local name = s.signal.name
      if config.ltn_signals[name] ~= nil then
        ctl.set_signal(config.ltn_signals[name].slot, s)
      else
        ctl.set_signal(misc_slot, s)
        misc_slot = misc_slot + 1
      end
    end
  end
end -- sort_signals()

--- Called to close the combinator UI
--- @param input EventData.CustomInputEvent | number This will either be a player_index or an EventData table
local function close(input)
  --- @type uint
  local ndx
  if type(input) == "table" then
    ndx = input.player_index
  else
    ndx = input --[[@as uint]]
  end
  local pt = global.players[ndx]
  local player = game.get_player(ndx)
  if player and player.valid then
    player.play_sound({path = "entity-close/ltn-combinator"})
  end

  if pt.uis.netui then
    netui.close(pt.uis.netui, ndx)
  end
  if pt.main_elems and pt.main_elems.ltnc_main_window then
    pt.main_elems.ltnc_main_window.destroy()
    pt.main_elems = nil
    pt.uis.main = nil
    pt.working_slot = nil
    pt.unit_number = nil
  end
end -- ltnc_ui.close()

-- Map the LTN settings to the ltn-signal that it controls
local ltn_setting_to_signal = {
  ["ltn-dispatcher-requester-threshold"] = "ltn-requester-threshold",
  ["ltn-dispatcher-provider-threshold"] = "ltn-provider-threshold",
  ["ltn-stop-default-network"] = "ltn-network-id"
}

--- Update the semi-constant "config"table with the new LTN settings
--- @param name string LTN Setting name that changed
local function runtime_setting_changed(name)
  if not ltn_setting_to_signal[name] then
    return
  end
  config.ltn_signals[ltn_setting_to_signal[name]].default
    = settings.global[name].value --[[@as number]]
end -- runtime_setting_changed()

--- Update the player runtime setting cache in global if the player changes thier settings
--- @param name string The setting that was changed
--- @param player_index uint Index of the player that changed their setting
local function player_setting_changed(name, player_index)
  local player_settings = global.players[player_index].settings
  player_settings[name] = settings.get_player_settings(player_index)[name].value
end -- player_setting_changed()

--- Toggle the state of the provider / requester services
--- @param ctl LuaConstantCombinatorControlBehavior
--- @param name string
--- @param state boolean
local function toggle_service_by_ctl(ctl, name, state)
  local cd = get_combinator_data(ctl.entity.unit_number)
  cd[name] = state
  for _, sig in ipairs{"threshold", "stack-threshold"} do
    local signal = "ltn-" .. name .. "-" .. sig
    local count = cd[signal]
    set_ltn_signal_by_control(ctl, count, signal)
    --update_ui_ltn_signal(self, signal)
  end
  --self.elems["check__" .. name].state = cd[name]
end -- toggle_service()

--- Toggle the state of the provider / requester services
--- @param self LTNC
--- @param name string
--- @param state boolean
local function toggle_service(self, name, state)
  toggle_service_by_ctl(self.control, name, state)
end -- toggle_service()
----------------------------------------------------------------------------------------------------
--#region Handlers

local handlers = {

--- @param e EventData.on_gui_click
--- @param self LTNC
network_id_config = function(self, e)
  local nf = self.elems.net_encode_flow
  local ef = self.elems.entity_preview_frame
  if nf.visible then
    nf.visible = false
    ef.visible = true
  else
    nf.visible = true
    ef.visible = false
  end
end, -- network_id_config()

--- @param e EventData.on_gui_click
--- @param self LTNC
network_id_toggle = function (self, e)
  local elem = e.element
  local netid_textbox = self.elems["text_entry__ltn-network-id"]
  netid_textbox.style = "ltnc_entry_text"
  if elem.name == "net_id_all" then
    update_ui_network_id_buttons(self, tt.on)
  elseif elem.name == "net_id_none" then
    update_ui_network_id_buttons(self, tt.off)
  elseif e.shift then
    netui.open_single(e, update_ui_network_id_buttons)
  else
    if elem.style.name == "ltnc_net_id_button_pressed" then
      elem.style = "ltnc_net_id_button"
    else
      elem.style = "ltnc_net_id_button_pressed"
    end
  end
  util.from_netid_buttons(self.player)
  local value = tonumber(netid_textbox.text) --[[@as integer]]
  set_ltn_signal(self, value, "ltn-network-id")
  update_ui_ltn_signal(self, "ltn-network-id")
end, -- network_id_toggle()

--- @param e EventData.on_gui_click
--- @param self LTNC
misc_signal_confirm = function(self, e)
  local pt = global.players[e.player_index]
  local ws = pt.working_slot
  local value = tonumber(ws.items.text)
  if not value then
    return
  end
  local elem = self.elems["misc_signal_slot__" .. ws.index]
  local name = elem.elem_value.name
  local type = elem.elem_value.type
  if pt.settings["ltnc-negative-signals"] and value > 0 
    and (type == "item" or type == "fluid") then
    value = value * -1
  end
  set_misc_signal(
    self,
    {count = value, signal = { name = name, type = type}},
    ws.index + config.ltnc_ltn_signal_count
  )
  update_ui_misc_signal(self, ws.index)
  reset_ui_misc_signal_contols(self)
end, -- misc_signal_confirm()

--- @param e EventData.on_gui_click
--- @param self LTNC
misc_signal_cancel = function(self, e)
  reset_ui_misc_signal_contols(self)
end,

--- @param e EventData.on_gui_text_changed
--- @param self LTNC
misc_signal_stacks_text_changed = function(self, e)
  util.from_stacks(self.player)
end, -- misc_signal_stacks_text_changed()

--- @param e EventData.on_gui_text_changed
--- @param self LTNC
misc_signal_items_text_chaged = function(self, e)
  util.from_items(self.player)
end, -- misc_signal_items_text_changed()

--- @param e EventData.on_gui_value_changed
--- @param self LTNC
misc_signal_slider_changed = function(self, e)
  util.from_slider(self.player)
end, -- misc_signal_slider_changed()

--- @param e EventData.on_gui_elem_changed
--- @param self LTNC
misc_signal_elem_changed = function(self, e)
  local elem = e.element
  if not elem.elem_value then
    return
  end
  if table.find(config.bad_signals, elem.elem_value.name) then
    game.print({"ltnc.bad-signal", elem.elem_value.name})
    elem.elem_value = nil
    return
  end
  local _, _, slot = string.find(elem.name, "__(%d+)")
  slot = tonumber(slot) --[[@as uint]]
  open_ui_misc_signal_edit_controls(self, slot)
end, -- misc_signal_elem_changed()

--- @param e EventData.on_gui_click
--- @param self LTNC
misc_signal_clicked = function(self, e)
  local elem = e.element
  local _, _, slot = string.find(elem.name, "__(%d+)")
  slot = tonumber(slot) --[[@as uint]]
  if e.button == defines.mouse_button_type.right then
    -- Right click, clear the slot
    elem.locked = false
    clear_misc_signal(self, slot)
    update_ui_misc_signal(self, slot)
    reset_ui_misc_signal_contols(self)
  elseif e.button == defines.mouse_button_type.left then
    -- Left click.  If the slot has a signal we don't want choose a new one, just update the value.
    if not elem.locked then
    return
  end
    open_ui_misc_signal_edit_controls(self, slot)
  end
end, -- misc_signal_clicked()

--- @param e EventData.on_gui_switch_state_changed
--- @param self LTNC
enable_disable_combinator = function(self, e)
  local ctl = self.control
  if not ctl.valid then
    return
  end
  if e.element.switch_state == "left" then
    ctl.enabled = false
  else
    ctl.enabled = true
  end
  update_ui(self)
end, -- enable_disable_combinator()

--- @param e EventData.on_gui_checked_state_changed
--- @param self LTNC
provide_request_state_changed = function(self, e)
  local elem = e.element
  local name = string.match(elem.name, "__(.*)")
  toggle_service(self, name, elem.state)
  update_ui(self)
end, -- ltnc_ui:provide_request()

--- @param e EventData.on_gui_checked_state_changed
--- @param self LTNC
ltn_checkbox_state_change = function(self, e)
  local elem = e.element
  if not elem then
    return
  end

  local name = string.match(elem.name, "__(.*)$")
  local value = 0
  if elem.state then
    value = 1
  end

  set_ltn_signal(self, value, name)
end, -- ltn_checkbox_state_change()

--- @param e EventData.on_gui_checked_state_changed
--- @param self LTNC
ltn_depot_toggle = function(self, e)
  if not e.element then
    return
  end

  local value = 0
  if e.element.state then
    value = 1
    toggle_service(self, "provider", not e.element.state)
    toggle_service(self, "requester", not e.element.state)
  end

  set_ltn_signal(self, value, "ltn-depot")
  -- element.state is true if we made the station a depot.  Therefore the req/prov panels should
  -- be disabled (not e.element.state)
  toggle_ui_req_prov_panels(self, not e.element.state)

  -- Remove and disable signals associated with requesters and providers
  for signal, details in pairs(config.ltn_signals) do
    if details.group == "provider" or details.group == "requester" then
      set_ltn_signal(self, 0, signal )
      --update_ui_ltn_signal(self, signal)
    end
  end

  update_ui(self)
end, -- ltn_depot_toggle()

--- @param e EventData.on_gui_text_changed
--- @param self LTNC
ltn_signal_textbox_changed = function(self, e)
  local elem = e.element
  local value = tonumber(e.text)
  local name = string.match(elem.name, "__(.*)$")
  -- value == nil is still valid - results in removing the signal and reverting to LTN default
  if not util.is_valid(name, value) then
    elem.style = "ltnc_entry_text_invaid_value"
    return
  end

  elem.style = "ltnc_entry_text"
  -- Do not remove signal while typing if they only deleted the text before typing
  -- If player explicitly types '0' remove the signal as typed
  if value then
    set_ltn_signal(self, value, name)
  end

  if name == "ltn-network-id" then
    update_ui_network_id_buttons(self)
  end
end, -- ltn_signignal_textbox_click()

--- @param e EventData.on_gui_click
--- @param self LTNC
ltn_signal_textbox_click = function(self, e)
  e.element.select_all()
  --e.element.style = "ltnc_entry_text"
end, -- ltn_signal_textbox_click()

--- @param e EventData.on_gui_confirmed
--- @param self LTNC
ltn_signal_textbox_confirmed = function(self, e)
  local elem = e.element
  --- @type LTNSignals
  local name = string.match(elem.name, "__(.*)$")
  local value = tonumber(elem.text) --[[@as integer]]
  if not util.is_valid(name, value) then
    elem.focus()
    return
  end
  -- If the player is CONFIRMING an empty edit box, remove the signal
  if not value then
    set_ltn_signal(self, value, name)
  end
  update_ui_ltn_signal(self, name)
end,

--- @param e EventData.CustomInputEvent
--- @param self LTNC
close_ltnc_ui = function(self, e)
  close(e)
end,
}

flib_gui.add_handlers(handlers, function(e, handler)
  local self = global.players[e.player_index].uis.main
  if self then
    handler(self, e)
  end
end)
--#endregion
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--#region GUI

--- Generate the tooltip for the LTN Signal textbox
--- @param name LTNSignals
--- @return LocalisedString
local function signal_tooltip(name)
  local d = config.ltn_signals[name]
  local max = d.max
  if name == "ltn-locked-slots" then
    -- Max wagon size...
    max = 40
  end
  return {
    "",
    { "ltnc-signal-tips." .. name },
    { "ltnc-signal-tips.zero-value" },
    {
      "ltnc-signal-tips.min-max-default",
      flib_format.number(d.min, false),
      flib_format.number(max, false),
      flib_format.number(d.default, false)
    }
  }
end -- signal_tooltip()

--- Render a checkbox
--- @param name string @ Name to give the textbox element "text_entry__\<name\>"
--- @param handler function|function[] @ Handler(s) for the checkbox
--- @param caption LocalisedString? @ Optional: Text next to the checkbox
--- @param tooltip LocalisedString? @ Optional: Checkbox's tooltip
--- @return GuiElemDef
local function check_box(name, handler, caption, tooltip)
  return
  {
    type = "checkbox",
    state = false,
    name = "check__" .. name,
    caption = caption or "",
    tooltip = tooltip or nil,
    handler = handler,
  }
end -- check_box()

--- Render LTN Signal textbox
--- @param name LTNSignals
--- @return GuiElemDef
local function ltn_signal_edit_box(name)
  local handler = {
    [defines.events.on_gui_text_changed] = handlers.ltn_signal_textbox_changed,
    [defines.events.on_gui_click] = handlers.ltn_signal_textbox_click,
    [defines.events.on_gui_confirmed] = handlers.ltn_signal_textbox_confirmed,
  }
  local negative = false
  if config.ltn_signals[name].min < 0 then
      negative = true
  end
  return
  {
    type = "textfield",
    style = "ltnc_entry_text",
    name = "text_entry__" .. name,
    numeric = true,
    allow_decimal = false,
    allow_negative = negative,
    clear_and_focus_on_right_click = true,
    lose_focus_on_confirm = true,
    tooltip = signal_tooltip(name),
    handler = handler,
  }
end -- ltn_signal_edit_box()

--- Render GuiElemDef for LTN signals in the given group
--- @param group LTNGroups @ Group to build signals for
--- @return GuiElemDef
local function ltn_signals_by_group(group)
  local group_signals =
      table.filter(
        config.ltn_signals,
        function(v) return v.group == group end
      )
  local elems = {}
  local function text_or_check(name)
    if group == "requester" and name == "ltn-disable-warnings" then
      return check_box(name, handlers.ltn_checkbox_state_change, nil, { "ltnc-signal-tips.ltn-disable-warnings" })
    else
      return ltn_signal_edit_box(name)
    end
  end

  for ltn_signal_name, _ in pairs(group_signals) do
    elems = table.array_merge { elems, {
      {
        type = "sprite",
        sprite = "virtual-signal/" .. ltn_signal_name,
        style = "ltnc_entry_sprite"
      },
      {
        type = "label",
        caption = { "virtual-signal-name." .. ltn_signal_name },
        style = "caption_label"
      },
      {
        type = "empty-widget",
        style = "flib_horizontal_pusher"
      },
      text_or_check(ltn_signal_name),
    } }
  end
  return elems
end -- ltn_signals_by_group()

--- Render a panel of LTN signal for the given group
--- @param group LTNGroups @ The group of singnals disired
--- @return GuiElemDef
local function ltn_signal_panel(group)
  return {
    type = "flow",
    direction = "vertical",
    { type = "label", style = "ltnc_header_label", caption = { "ltnc." .. group } },
    {
      type = "frame",
      direction = "vertical",
      style = "flib_shallow_frame_in_shallow_frame",
      style_mods = { padding = 6 },
      {
        type = "table",
        name = "table_" .. group,
        column_count = 4,
        style_mods = { cell_padding = 2, horizontally_stretchable = true },
        children = ltn_signals_by_group(group)
      }
    }
  }
end -- ltn_signal_panel()

--- Render GuiElemDef for the miscelaneous signal slot buttons
--- @param slot_count integer @ Number of signal slots to build
--- @return GuiElemDef
local function misc_signal_buttons(slot_count)
  local buttons = {}

  for i = 1, slot_count do
    buttons[i] = {
      type = "choose-elem-button",
      name = "misc_signal_slot__" .. tostring(i),
      sytle = "flib_slot_button_default",
      elem_type = "signal",
      handler = {
        [defines.events.on_gui_elem_changed] = handlers.misc_signal_elem_changed,
        [defines.events.on_gui_click] = handlers.misc_signal_clicked,
      },
      {
        type = "label",
        style = "signal_count",
        ignored_by_interaction = true,
        caption = "",
      }
    }
  end
  return buttons
end -- misc_signal_button()

--- Generate the butons for the network encoder UI
--- @param buttons uint
--- @return GuiElemDef
local function net_encode_toggle_buttons(buttons)
  local t =
  {
    type = "table",
    name = "net_encode_table",
    column_count = 8,
    children = {},
  }
  for i = 1, buttons do
    t.children[i] =
    {
      type = "sprite-button",
      handler = { [defines.events.on_gui_click] = handlers.network_id_toggle },
      style = "ltnc_net_id_button",
      caption = tostring(i),
      mouse_button_filter = { "left" },
    }
  end
  return t
end -- net_encode_toggle_buttons()

--- Build the LTN Main UI window
--- @param player LuaPlayer @ Player object that is opening the combinator
--- @return GuiElemDef
local function build(player)
  local elems = flib_gui.add(player.gui.screen, {
    { -- Main Window Frame
      type = "frame",
      direction = "vertical",
      name = "ltnc_main_window",
      handler = { [defines.events.on_gui_closed] = handlers.close_ltnc_ui},
      { -- Title Bar
        type = "flow",
        style = "flib_titlebar_flow",
        drag_target = "ltnc_main_window",
        {
          type = "label",
          style = "frame_title",
          caption = { "ltnc.window-title" },
          ignored_by_interaction = true,
        },
        {
          type = "empty-widget",
          style = "flib_titlebar_drag_handle",
          ignored_by_interaction = true,
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close_white",
          hovered_sprite = "utility/close_black",
          clicked_sprite = "utility/close_black",
          mouse_button_filter = { "left" },
          handler = { [defines.events.on_gui_click] = handlers.close_ltnc_ui },
        }
      },
      { -- UI Content
        type = "flow",
        { -- Primary panel
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          direction = "vertical",
          style_mods = { top_padding = 8 },
          { -- Status indicator
            type = "flow",
            style = "flib_indicator_flow",
            style_mods = { bottom_padding = 10 },
            {
              type = "sprite",
              name = "status_indicator",
              sprite = "flib_indicator_green",
              style_mods = { size = 16, stretch_image_to_widget_size = true },
            },
            {
              type = "label",
              name = "status_label",
              caption = { "ltnc.status-working" },
            }
          },
          { -- Network Encode Pane
            type = "flow",
            name = "net_encode_flow",
            visible = false,
            direction = "vertical",
            {
              type = "flow",
              style_mods = {
                horizontally_stretchable = true,
                minimal_height = 128,
                vertical_align = "center",
                bottom_margin = 8
              },
              net_encode_toggle_buttons(32),
              {
                type = "flow",
                direction = "vertical",
                style_mods = {
                  horizontally_stretchable = true,
                  vertically_stretchable = true,
                  minimal_height = 128,
                  horizontal_align = "right",
                  vertical_align = "center",
                },
                {
                  type = "button",
                  name = "net_id_all",
                  handler = { [defines.events.on_gui_click] = handlers.network_id_toggle },
                  caption = { "ltnc.btn-all" },
                  tooltip = { "ltnc-signal-tips.ltn-network-id-all" }
                },
                {
                  type = "button",
                  name = "net_id_none",
                  handler = { [defines.events.on_gui_click] = handlers.network_id_toggle },
                  caption = { "ltnc.btn-none" },
                  tooltip = { "", { "ltnc-signal-tips.ltn-network-id-none" }, { "ltnc-signal-tips.zero-value" } },
                },
                ltn_signal_edit_box("ltn-network-id"),
              },
            },
          },
          { -- Entity Preview
            type = "frame",
            name = "entity_preview_frame",
            style = "flib_shallow_frame_in_shallow_frame",
            style_mods = { bottom_margin = 8 },
            {
              type = "entity-preview",
              name = "entity_preview",
              style_mods = {
                minimal_height = 128,
                horizontally_stretchable = true,
                vertically_stretchable = true,
              },
            }
          },
          { -- Network ID
            type = "table",
            name = "netid",
            column_count = 2,
            style_mods = { cell_padding = 2, horizontally_stretchable = true },
            {
              type = "sprite-button",
              style = "ltnc_small_button",
              sprite = "virtual-signal/ltn-network-id",
              tooltip = { "ltnc.net-config-tip" },
              handler = { [defines.events.on_gui_click] = handlers.network_id_config },
              mouse_button_filter = { "left" },
            },
            {
              type = "label",
              style = "caption_label",
              name = "label__ltn-network-id",
            }
          },
          { -- On/Off switch / Services / Depot priority
            type = "table",
            column_count = 5,
            style_mods = { horizontally_stretchable = true, cell_padding = 2 },
            { -- Switch
              type = "flow",
              direction = "vertical",
              { type = "label", caption = { "ltnc.output" } },
              {
                type = "switch",
                name = "on_off",
                left_label_caption = { "ltnc.off" },
                right_label_caption = { "ltnc.on" },
                handler = { [defines.events.on_gui_switch_state_changed] = handlers.enable_disable_combinator },
              }
            },
            { type = "empty-widget", style = "flib_horizontal_pusher" },
            { -- Request / Provide
              type = "flow",
              direction = "vertical",
              check_box(
                "provider",
                { [defines.events.on_gui_checked_state_changed] = handlers.provide_request_state_changed },
                { "ltnc.provider" },
                { "ltnc.provider-tip" }
              ),
              check_box(
                "requester",
                { [defines.events.on_gui_checked_state_changed] = handlers.provide_request_state_changed },
                { "ltnc.requester" },
                { "ltnc.requester-tip" }
              ),
              check_box(
                "ltn-depot",
                { [defines.events.on_gui_checked_state_changed] = handlers.ltn_depot_toggle },
                { "ltnc.depot" },
                { "ltnc-signal-tips.ltn-depot" }
              ),
            },
            { -- Depot Priority
              type = "flow",
              direction = "vertical",
              style_mods = { horizontal_align = "right" },
              {
                type = "table",
                column_count = 2,
                style_mods = { cell_padding = 2, horizontally_stretchable = true },
                {
                  type = "sprite",
                  sprite = "virtual-signal/ltn-depot-priority",
                  style = "ltnc_entry_sprite"
                },
                {
                  type = "label",
                  caption = { "virtual-signal-name.ltn-depot-priority" },
                  style = "caption_label",
                },
                { type = "empty-widget" },
                ltn_signal_edit_box("ltn-depot-priority"),
              },
            },
          },
          { -- Line
            type = "line", style_mods = { top_margin = 4, bottom_margin = 4 }
          },
          {
            type = "flow",
            style_mods = { minimal_height = 56 },
            {
            type = "flow",
            direction = "vertical",
            name = "stack_item_flow",
            { --Stack / Item / Confirm
              type = "flow",
              style_mods = { vertical_align = "center" },
              { type = "empty-widget", style = "flib_horizontal_pusher" },
              {
                type = "flow",
                name = "stack_flow",
                { type = "label",        caption = { "ltnc.label-stacks" } },
                {
                  type = "textfield",
                  style = "ltnc_entry_text",
                  name = "text_entry__stacks",
                  elem_mods = { enabled = false },
                  numeric = true,
                  allow_negative = true,
                  allow_decimal = true,
                  lose_focus_on_confirm = true,
                  clear_and_focus_on_right_click = true,
                  handler = {
                    [defines.events.on_gui_text_changed] = handlers.misc_signal_stacks_text_changed,
                    [defines.events.on_gui_confirmed] = handlers.misc_signal_confirm,
                  },
                },
              },
              { type = "label", caption = { "ltnc.label-items" } },
              {
                type = "textfield",
                style = "ltnc_entry_text",
                name = "text_entry__item_fluid",
                elem_mods = { enabled = false },
                numeric = true,
                allow_negative = true,
                allow_decimal = true,
                lose_focus_on_confirm = true,
                clear_and_focus_on_right_click = true,
                handler = {
                  [defines.events.on_gui_text_changed] = handlers.misc_signal_items_text_chaged,
                  [defines.events.on_gui_confirmed] = handlers.misc_signal_confirm,
                },
              },
              {
                type = "sprite-button",
                style = "ltnc_confirm_button",
                name = "signal_quantity_confirm",
                elem_mods = { enabled = false },
                mouse_button_filter = { "left" },
                sprite = "utility/check_mark",
                handler = { [defines.events.on_gui_click] = handlers.misc_signal_confirm },
              },
              {
                type = "sprite-button",
                style = "ltnc_cancel_button",
                name = "signal_quantity_cancel",
                elem_mods = { enabled = false },
                mouse_button_filter = { "left" },
                sprite = "utility/reset",
                handler = { [defines.events.on_gui_click] = handlers.misc_signal_cancel },
              },
            },
            { -- Slider
              type = "slider",
              name = "misc_signal_slider",
              elem_mods = { enabled = false },
              style_mods = {
                horizontally_stretchable = true,
                top_margin = 4,
                bottom_margin = 4
              },
              minimum_value = -1,
              maximum_value = 50,
              handler = { [defines.events.on_gui_value_changed] = handlers.misc_signal_slider_changed }
            },
          },
          },
          { type = "line", style_mods = { top_margin = 4, bottom_margin = 4 }},
          { -- Signal Table Label
            type = "label",
            style = "ltnc_header_label",
            caption = { "ltnc.output-signals" }
          },
          { -- Miscelaneous signal table
            type = "frame",
            direction = "vertical",
            style = "slot_button_deep_frame",
            {
              type = "table",
              style = "slot_table",
              column_count = 10,
              children = misc_signal_buttons(config.ltnc_misc_signal_count)
            }
          },
        },
        { -- Spacing
          type = "empty-widget",
          style_mods = { width = 2 },
          visible = true,
        },
        { -- LTN Signal panels
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          direction = "vertical",
          style_mods = { top_padding = 4 },
          visible = true,
          ltn_signal_panel("common"),
          ltn_signal_panel("provider"),
          ltn_signal_panel("requester"),
        }
      }
    }
  })
  return elems
end -- build()
--#endregion
----------------------------------------------------------------------------------------------------

--- Called to open the combinator UI
--- @param player LuaPlayer
--- @param entity LuaEntity
local function open_gui(player, entity)
  local pt = global.players[player.index]
  -- Check to see if the player has an LTNC open already.
  if pt.unit_number then
    if pt.unit_number == entity.unit_number then
      -- Player already has this combinator open.  Reset player.opened to the existing UI.
      player.opened = pt.main_elems.ltnc_main_window
      return
    end

    --  Opening a different LTN Combinator, need to fisrt close the existing before opening the new.
    close(player.index)
  end

  --- @type LTNC
  local new_ui = {}
  new_ui.player = player
  new_ui.entity = entity
  new_ui.control = new_ui.entity.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  new_ui.elems = build(player)
  new_ui.elems.entity_preview.entity = new_ui.entity
  new_ui.elems.ltnc_main_window.force_auto_center()
  sort_signals(new_ui)
  update_ui(new_ui)

  pt.uis.main = new_ui
  pt.main_elems = new_ui.elems
  pt.unit_number = new_ui.entity.unit_number

  player.opened = pt.main_elems.ltnc_main_window
end -- open_gui()

--- @param player LuaPlayer
--- @param entity LuaEntity
local function increase_reach(player, entity)
  if player.controller_type ~= defines.controllers.character then
    return
  end

  local pt = global.players[player.index]
  local new_reach_bonus = flib_position.distance(player.position, entity.position)
  pt.original_reach_bonus = player.character_reach_distance_bonus
  player.character_reach_distance_bonus = new_reach_bonus
end -- increase_reach()

--- @param player LuaPlayer
local function reset_reach(player)
  if player.controller_type ~= defines.controllers.character then
    return
  end

  local pt = global.players[player.index]
  if not pt.original_reach_bonus then
    return
  end

  player.character_reach_distance_bonus = pt.original_reach_bonus
  pt.original_reach_bonus = nil
end -- reset_reach()

--- Open GUI if on the map or temporarily increase reach if trying to open and LNTC
--- out of normal reach range since this is a train control system.
--- Similar behavior as train-stops.
--- @param e EventData.CustomInputEvent
local function on_linked_open_gui(e)
  if not e.selected_prototype or e.selected_prototype.name ~= "ltn-combinator" then
    return
  end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then
    return
  end

  local entity = player.selected
  if not entity or not entity.valid then
    return
  end

  local lamp = util.find_connected_entity("logistic-train-stop-input", {[entity.unit_number] = entity}, 10)
  if player.render_mode == defines.render_mode.chart_zoomed_in then
    if player.cursor_stack and player.cursor_stack.valid_for_read then
      return
    end

    if not lamp or not lamp.valid then
      player.create_local_flying_text({ text = {"ltnc.not-connected"}, create_at_cursor = true })
      return
    end

    open_gui(player, entity)
    return
  end

  -- Increase the players reach if they are not in map mode and the LTN Combinator is out of
  -- thier reach.  Then let the game open the gui.  Reach needs to be reset in the open function.
  if player.render_mode == defines.render_mode.game and not player.can_reach_entity(entity) then
    if player.cursor_stack and player.cursor_stack.valid_for_read then
      return
    end

    if not lamp or not lamp.valid then
      player.create_local_flying_text({ text = {"ltnc.not-connected"}, create_at_cursor = true })
      return
    end

    increase_reach(player, entity)
  end
end -- on_linked_open_gui()

--- Handle opening the custom GUI to replace the builtin one when it opend.
--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  local player = game.get_player(e.player_index)
  if not player or player.opened_gui_type ~= defines.gui_type.entity then
    return
  end

  local entity = e.entity
    if not entity or not entity.valid or entity.name ~= "ltn-combinator" then
    return
  end

  open_gui(player, entity)
  reset_reach(player)
end

--- When building a new entity set defaults according to mod settings
--- @param e BuildEvent
local function on_built(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or entity.name ~= "ltn-combinator" then
    return
  end

  -- TODO:  Better thinking through.   It is disabling when fast-replacing const combi

  -- If tags exist, copy them to global 
  local cd = e.tags and e.tags["LTNC"] or {} --[[@as CombinatorData]]
  if next(cd) == nil then
    -- New, blank combinator, initialize state
    cd.provider = true
    cd.requester = true
  end

  global.combinators[entity.unit_number] = cd
  -- TODO: Disable on blueprint build
  local build_disable = settings.global["ltnc-disable-built-combinators"].value
  local ctl = entity.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  if build_disable == "requester" then
    toggle_service_by_ctl(ctl, "requester", false)
  elseif build_disable == "provider" then
    toggle_service_by_ctl(ctl, "provider", false)
  elseif build_disable == "all" then
    toggle_service_by_ctl(ctl, "provider", false)
    toggle_service_by_ctl(ctl, "requester", false)
  end
end -- on_built()

--- @param e EventData.on_player_setup_blueprint
local function on_player_setup_blueprint(e)
  local bp = util.get_blueprint(e)
  if not bp then
    return
  end

  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end

  for i, entity in pairs(entities) do
  --- @cast i uint
    if entity.name ~= "ltn-combinator" then
      goto continue
    end

    local real_entity = e.surface.find_entity(entity.name, entity.position)
    if not real_entity then
      goto continue
    end

    -- CD to tags...
    bp.set_blueprint_entity_tag(i, "LTNC", get_combinator_data(real_entity.unit_number))
    ::continue::
  end

end -- on_plyaer_setup_blueprint()

local function on_player_removed(e)
  global.players[e.player_index] = nil
end -- on_player_removed()

local function on_player_created(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  player_data.init(player)
end -- on_player_created()

local function on_settings_changed(e)
  if e.setting_type == "runtime-per-user" then
    player_setting_changed(e.setting, e.player_index)

  else
    runtime_setting_changed(e.setting)
  end
end -- on_settings_changed()

--- @param e DestroyEvent
local function on_destroy(e)
  local entity = e.entity
  if not entity or not entity.valid then
    return
  end

  local name = entity.name
  local unit_number = entity.unit_number
  if name == "entity-ghost" then
    name = entity.ghost_name
    unit_number = entity.ghost_unit_number
  end

  if name ~= "ltn-combinator" or not unit_number then
    return
  end

  global.combinators[unit_number] = nil
end -- on_destroy()

--- @param e EventData.on_post_entity_died
local function on_post_died(e)
  if e.prototype.name ~= "ltn-combinator" then
    return
  end

  local ghost = e.ghost
  if not ghost or not ghost.valid or not e.unit_number then
    return
  end

  ghost.tags = { ["LTNC"] = global.combinators[e.unit_number] }
  global.combinators[e.unit_number] = nil
end -- on_post_died()

--- @param e EventData.on_entity_settings_pasted
local function on_settings_pasted(e)
  local player = game.get_player(e.player_index)
  if player and player.valid then
    reset_reach(player)
  end

  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end

  if source.name ~= "ltn-combinator" or destination.name ~= "ltn-combinator" then
    return
  end

  local cd = global.combinators
  cd[destination.unit_number] = table.deep_copy(cd[source.unit_number])
end -- on_settings_pasted()

---@param e EventData.CustomInputEvent
local function on_linked_paste_settings(e)
  if not e.selected_prototype
  or e.selected_prototype.base_type ~= "entity"
  or e.selected_prototype.name ~= "ltn-combinator" then
    return
  end

  local player = game.get_player(e.player_index)
  if not player or not player.valid
  or not player.entity_copy_source or not player.entity_copy_source.valid
  or player.entity_copy_source.type ~= "constant-combinator"
  or not player.selected
  or not player.selected.valid then
    return
  end

  local dest = player.selected --[[@as LuaEntity]]
  if player.controller_type == defines.controllers.character
  and not player.can_reach_entity(dest) then
    increase_reach(player, dest)
  end
end

--- @class LTNC
--- @field entity LuaEntity
--- @field control LuaConstantCombinatorControlBehavior
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer Player operating this UI
local ltnc = {}

function ltnc.on_init()
  global_data.init()
  for _, player in pairs(game.players) do
    player_data.init(player)
  end

  for k, _ in pairs(ltn_setting_to_signal) do
    runtime_setting_changed(k)
  end
end -- on_init()

function ltnc.on_load()
  for k, _ in pairs(ltn_setting_to_signal) do
    runtime_setting_changed(k)
  end
end -- on_load()

--- Find closest LTN combinator on a circuit network attached to this entity
--- @param entity LuaEntity # Target entity to begin search for connected combinator
--- @return LuaEntity? # The LTN Combinator or nil if none found within max_depth
local function find_attached_ltn_combinator(entity)

  if not entity or not entity.valid then
    return
  end

  local first_entity = {[entity.unit_number] = entity}
  return util.find_connected_entity("ltn-combinator", first_entity, 10)
end -- find_attached_ltn_combinator()

function ltnc.add_commands()
  --[[
  commands.add_command("dumpcombi", nil, function()
    game.print(serpent.block(global.combinators))
  end)
  commands.add_command("findcombi", nil, function(e)
    local entity = game.get_player(e.player_index).selected
    if not entity or not entity.valid then
      return
    end

    local found = find_attached_ltn_combinator(entity)
    if not found or not found.valid then
      game.print("LTN Combinator not found!")
      return
    end

    game.print(string.format("Combi: %d - Name: %s",found.unit_number, found.name))
  end)
  ]]

  commands.add_command("ltnc-unset-requester", {"ltnc.unset-requester-help"}, function()
    local entities = {}
    for _, surface in pairs(game.surfaces) do
      entities = table.array_merge({entities, surface.find_entities_filtered({name = "ltn-combinator"})})
    end
    for _, entity in ipairs(entities) do
      local ctl = entity.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
      for i = config.ltnc_ltn_signal_count + 1, config.ltnc_slot_count do
        --- @cast i uint
        local signal = ctl.get_signal(i)
        if signal.signal and signal.count < 0 then
          goto continue
        end
      end

      toggle_service_by_ctl(ctl, "requester", false)
      ::continue::
    end
  end)
end -- add_commands()

--- Open closest combinator to the supplied entity found on an attached circuit network
--- @param player_index uint
--- @param entity LuaEntity
--- @param register boolean? # Currently not implemented
--- @return boolean
local function remote_open_gui(player_index, entity, register)
  if not entity or not entity.valid or entity.type == "entity-ghost" then
    return false
  end

  local player = game.get_player(player_index)
  if not player or not player.valid then
    return false
  end

  local combinator = find_attached_ltn_combinator(entity)
  if not combinator or not combinator.valid then
    return false
  end

  open_gui(player, combinator)
  return true
end -- remote_open_gui()

function ltnc.add_remote_interface()
  remote.add_interface("ltn-combinator", {
    -- Usage: result = remote.call("ltn-combinator", "open_ltn_combinator", player_index (integer), entity (LuaEntity), register (boolean))
    --  player_index: (required)
    --  entity: any entity that is in the same green-circuit-network as the wanted ltn-combinator (required)
    --  register: registers the opened window in game.player[i].opened (optional, default true)
    --  returns a boolean, whether a combinator was opened
    open_ltn_combinator = remote_open_gui,
    -- Usage: result = remote.call("ltn-combinator", "close_ltn_combinator", player_index (integer))
    --  player_index: (required)
    --
    --  Calling this interface is only required if a ltn-combinator was previously opened with register = false.
    --  Use this method to keep your own window open.
    close_ltn_combinator = close
  })
end -- add_remote_interfaces()

ltnc.events = {
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_removed] = on_player_removed,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_built_entity] = on_built,
  [defines.events.on_entity_cloned] = on_built,
  [defines.events.on_robot_built_entity] = on_built,
  [defines.events.script_raised_built] = on_built,
  [defines.events.script_raised_revive] = on_built,
  [defines.events.on_robot_mined_entity] = on_destroy,
  [defines.events.on_player_mined_entity] = on_destroy,
  [defines.events.script_raised_destroy] = on_destroy,
  [defines.events.on_post_entity_died] = on_post_died,
  [defines.events.on_entity_settings_pasted] = on_settings_pasted,
  ["ltnc-linked-open-gui"] = on_linked_open_gui,
  ["ltnc-linked-paste-settings"] = on_linked_paste_settings,
}

return ltnc
