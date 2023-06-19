local _options = ...

local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _homedir = path.combine(os.cwd(), "data")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _services = require"__xtz.services"
for serviceId, _ in pairs(_services.signer) do 
	local _ok, _status, _started = _systemctl.safe_get_service_status(serviceId)
	ami_assert(_ok and _status ~= "running", serviceId .. " is already running. Please stop it to import keys...", EXIT_APP_INTERNAL_ERROR)
end

local _ledgerId = _options["ledger-id"]
if type(_ledgerId) ~= "string" then 
	local _proc = proc.spawn("bin/client", { "list", "connected", "ledgers" }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = _homedir }
	})

	ami_assert(_proc.exitcode == 0, "Failed to get connected ledgers: " .. _proc.stderrStream:read("a"))
	local _output = _proc.stdoutStream:read("a")
	_ledgerId = _output:match("## Ledger `(.-)`")
end

local _derivationPath = _options and _options["derivation-path"]
if type(_derivationPath) ~= "string" then
	if _derivationPath ~= nil then
		log_warn("Invalid derivation path detected. Falling back to default!")
	end
	_derivationPath = "ed25519/0h/0h"
end

ami_assert(type(_ledgerId) == "string", "Failed to get ledger id!")

log_info("Please confirm key import for signer...")
local _proc = proc.spawn("bin/signer", { "import", "secret", "key", _options.alias or "baker", "ledger://" .. _ledgerId .. "/" .. _derivationPath, _options.force and "--force" or nil }, {
	stdio = "inherit",
	wait = true,
	env = { HOME = _homedir }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key to signer!")

log_info("Please confirm key import for client...")
local _proc = proc.spawn("bin/client", { "import", "secret", "key", _options.alias or "baker", "ledger://" .. _ledgerId .. "/" .. _derivationPath, _options.force and "--force" or nil }, {
	stdio = "inherit" ,
	wait = true,
	env = { HOME = _homedir }
})
ami_assert(_proc.exitcode == 0, "Failed to import key to client!")

log_success("Keys successfully imported.")
