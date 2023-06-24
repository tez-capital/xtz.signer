local _options = ...

local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _homedir = path.combine(os.cwd(), "data")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)
local _services = require("__xtz.services")
local _ok, _status, _started = _systemctl.safe_get_service_status(_services.signerServiceId)

local _args = { "setup", "ledger", "to", "bake", "for", (_options.alias or "baker") }
if _ok and _status == "running" then
	table.insert(_args, 1, "--remote-signer")
	table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
end

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
ami_assert(_proc.exitcode == 0 or not _stderr:match("Error:"), "Failed to setup ledger for baking: " .. (_stderr or ""))

log_success("Ledger setup successful.")