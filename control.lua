MOD_STRING  = "LTN Combinator"

print, dlog = require "script.logger" ()
local config = require("config")
local on_built = require("script.on_built")
local event = require("__flib__.event")
require("script.gui")
require("script.remote")

-- TODO: Move mod / settings init here

-- grab default threshold from ltn settings
if settings.global["ltn-dispatcher-requester-threshold"] then
  local threshold = settings.global["ltn-dispatcher-requester-threshold"].value
  config.ltn_signals["ltn-requester-threshold"].default = threshold
end

if settings.global["ltn-dispatcher-provider-threshold"] then
  local threshold = settings.global["ltn-dispatcher-provider-threshold"].value
  config.ltn_signals["ltn-provider-threshold"].default = threshold
end

if settings.global["ltn-stop-default-network"] then
  local default_networkid = settings.global["ltn-stop-default-network"].value
  config.ltn_signals["ltn-network-id"].default = default_networkid
end

script.on_event({defines.events.on_runtime_mod_setting_changed}, function(e)
  if e.setting == "ltn-dispatcher-requester-threshold" then
    local threshold = settings.global["ltn-dispatcher-requester-threshold"].value
    config.ltn_signals["ltn-requester-threshold"].default = threshold
  elseif e.setting == "ltn-dispatcher-provider-threshold" then
    local threshold = settings.global["ltn-dispatcher-provider-threshold"].value
    config.ltn_signals["ltn-provider-threshold"].default = threshold
  elseif e.setting == "ltn-stop-default-network" then
    local default_networkid = settings.global["ltn-stop-default-network"].value
    config.ltn_signals["ltn-network-id"].default = default_networkid
  end
end)

local ev = defines.events
event.register(
  {ev.on_built_entity, ev.on_robot_built_entity, ev.script_raised_built, ev.script_raised_revive},
  on_built.check_built_entity,
  {
    {filter="type", type="constant-combinator"},
    {filter="name", name="ltn-combinator", mode="and"}
  }
)