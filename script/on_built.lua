local me = {}
function me.check_built_entity(event)
	if settings.global["disable-built-combinators"].value then
		local built_entity = event.created_entity or event.entity
		if not built_entity then
			return
		end
		if built_entity.type == "constant-combinator" and built_entity.name == "ltn-combinator" then
			local control_behavior = built_entity.get_control_behavior()
			if control_behavior and control_behavior.enabled then
				control_behavior.enabled = false
			end
		end
	end
end
return me