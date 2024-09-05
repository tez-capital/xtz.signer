local _options = ...
-- tezos-client set deposit limit for <delegate> to <deposit_limit>
-- tezos-client unset deposit limit for <delegate>

local _homedir = path.combine(os.cwd(), "data")
ami_assert((_options.set and not _options.unset) or (not _options.set and _options.unset), "You can not set and unset at the same time!")
ami_assert(_options.set or _options.unset, "You have to specify whether to set or unset!")

local serviceManager = require"__xtz.service-manager"
local _services = require("__xtz.services")
local _ok, _status, _ = serviceManager.safe_get_service_status(_services.signerServiceId)

local _args = { "set", "deposits", "limit", "for", "baker", "to", _options.set }
if _options.unset then
	_args = { "unset", "deposits", "limit", "for", "baker" }
end

if _ok and _status == "running" then
	table.insert(_args, 1, "--remote-signer")
	table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
end

local _proc = proc.spawn("bin/client", _args, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = _homedir }
})

log_info("Please confirm adjusting of deposit limits...")
local _stderr = _proc.stderrStream:read("a") or ""
ami_assert(_proc.exitcode == 0, "Failed to set/unset deposits limit: " .. _stderr)

log_success("Deposits limit adjusted.")