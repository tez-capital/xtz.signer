local _options = ...

local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _homedir = _user == "root" and "/root" or "/home/" .. _user
local _keyId = am.app.get_configuration("keyId", "baker")
local _args = { "setup", "ledger", "to", "bake", "for", _keyId }
if _options["main-chain-id"] then 
	table.insert(_args, "--main-chain-id")
	table.insert(_args, _options["main-chain-id"])
end

if _options["main-hwm"] then 
	table.insert(_args, "--main-hwm")
	table.insert(_args, _options["main-hwm"])
end

local _proc = proc.spawn("bin/client", _args, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = _homedir }
})

local _stderr = _proc.stderrStream:read("a")
ami_assert(_proc.exitcode == 0 or _stderr:match("Error:"), "Failed to setup ledger for baking: " .. _stderr)

log_success("Ledger setup successful.")