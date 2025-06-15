local options, _, args, _ = ...

local args_values = table.map(args, function(v) return v.arg end)
local services = require("__xtz.services")

local to_check = table.values(services.active_names)
if #args_values > 0 then
    to_check = {}
    for _, v in ipairs(args_values) do
        if type(services.active_names[v]) == "string" then
            table.insert(to_check, services.active_names[v])
        end
    end
end

local service_manager = require("__xtz.service-manager")
service_manager.logs(to_check, options)