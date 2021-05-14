local desc = global.network_icons or {}

for i=1, 32 do
    if desc[i] then
        desc[i] = {icon = desc[i]}
    else
        desc[i] = {}
    end
end

global.network_icons = nil
global.network_description = desc
