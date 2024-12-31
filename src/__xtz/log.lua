local options, _, args, _ = ...

local args = table.map(args, function(v) return v.arg end)
local services = require("__xtz.services")

local to_check = table.values(services.all_names)
if #args > 0 then
    to_check = {}
    for _, v in ipairs(args) do
        if type(services.signer_service_names[v]) == "string" then
            table.insert(to_check, services.signer_service_names[v])
        end
    end
end

local journalctl_args = { "journalctl" }
if options.follow then table.insert(journalctl_args, "-f") end
if options['end'] then table.insert(journalctl_args, "-e") end
if options.since then
    table.insert(journalctl_args, "--since")
    table.insert(journalctl_args, '"' .. tostring(options.since) .. '"')
end
if options["until"] then
    table.insert(journalctl_args, "--until")
    table.insert(journalctl_args, '"' .. tostring(options["until"]) .. '"')
end
for _, v in ipairs(to_check) do
    table.insert(journalctl_args, "-u")
    table.insert(journalctl_args, v)
end

os.execute(string.join(" ", table.unpack(journalctl_args)))