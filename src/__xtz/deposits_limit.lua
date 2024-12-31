local options = ...
-- tezos-client set deposit limit for <delegate> to <deposit_limit>
-- tezos-client unset deposit limit for <delegate>

local home_directory = path.combine(os.cwd(), "data")
ami_assert((options.set and not options.unset) or (not options.set and options.unset), "You can not set and unset at the same time!")
ami_assert(options.set or options.unset, "You have to specify whether to set or unset!")

local service_manager = require"__xtz.service-manager"
local services = require("__xtz.services")
local ok, status, _ = service_manager.safe_get_service_status(services.signer_service_id)
local args = { "set", "deposits", "limit", "for", "baker", "to", options.set }
if options.unset then
	args = { "unset", "deposits", "limit", "for", "baker" }
end

if ok and status == "running" then
	table.insert(args, 1, "--remote-signer")
	table.insert(args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
end

local process = proc.spawn("bin/client", args, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = home_directory }
})

log_info("Please confirm adjusting of deposit limits...")
local stderr = process.stderr_stream:read("a") or ""
ami_assert(process.exit_code == 0, "Failed to set/unset deposits limit: " .. stderr)

log_success("Deposits limit adjusted.")