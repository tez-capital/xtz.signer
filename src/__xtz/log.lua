local _options, _, args, _ = ...

local _args = table.map(args, function(v) return v.arg end)
local _services = require("__xtz.services")

local _toCheck = table.values(_services.allNames)
if #_args > 0 then
    _toCheck = {}
    for _, v in ipairs(_args) do
        if type(_services.signerServiceNames[v]) == "string" then
            table.insert(_toCheck, _services.signerServiceNames[v])
        end
    end
end

local _journalctlArgs = { "journalctl" }
if _options.follow then table.insert(_journalctlArgs, "-f") end
if _options['end'] then table.insert(_journalctlArgs, "-e") end
for _, v in ipairs(_toCheck) do
    table.insert(_journalctlArgs, "-u")
    table.insert(_journalctlArgs, v)
end

os.execute(string.join(" ", table.unpack(_journalctlArgs)))