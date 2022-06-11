local me = {}
local config = require("config")
local signals = config.ltn_signals
local gsettings = settings.global

function me.check_built_entity(event)
  local built_entity = event.created_entity or event.entity
  if not built_entity then return end

  local ltnc = ltn_combinator:new(built_entity)
  if not ltnc then return end
  local stop_type = ltnc:get_stop_type()
  if gsettings["ltnc-disable-built-combinators"].value == "all" then
    ltnc:set_enabled(false)
  elseif gsettings["ltnc-disable-built-combinators"].value == "requester-only" and
          stop_type == config.LTN_STOP_REQUESTER then
    ltnc:set_enabled(false)
  end
  if gsettings["ltnc-emit-default-network-id"].value then
    local netid = ltnc:get("ltn-network-id")
    if netid == signals["ltn-network-id"].default then
      ltnc:set("ltn-network-id", netid)
    end
  end
end

return me
