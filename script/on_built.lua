local me = {}
local config = require("config")
local signals = config.ltn_signals

function me.check_built_entity(event)
    local built_entity = event.created_entity or event.entity
    if not built_entity then
      return
    end
    if built_entity.type == "constant-combinator" and built_entity.name == "ltn-combinator" then
      local control_behavior = built_entity.get_or_create_control_behavior()
      if settings.global["disable-built-combinators"].value then
        if control_behavior and control_behavior.enabled then
          control_behavior.enabled = false
        end
      end
      if settings.global["emit-default-network-id"].value then
        if control_behavior then
          local slot = signals["ltn-network-id"].slot
          local signal = control_behavior.get_signal(slot)
          if not signal.signal then 
            signal = {signal = {type = "virtual", name = "ltn-network-id",},
                      count = signals["ltn-network-id"].default}
          end
          control_behavior.set_signal(slot, signal)
        end
      end
    end
  end
return me
