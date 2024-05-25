---@param options table<string, any>
local function setup(options)
	if not options["authorize"] then
		log_debug("Skipping ledger/authorize setup...")
		return
	end

	log_info("Authorizing ledger for baking...")

	local serviceManager = require "__xtz.service-manager"
	local _services = require("__xtz.services")
	local _ok, _status, _ = serviceManager.safe_get_service_status(_services.signerServiceId)

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	local _args = { "setup", "ledger", "to", "bake", "for", alias }
	if _ok and _status == "running" then
		table.insert(_args, 1, "--remote-signer")
		table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
	end

	table.insert(_args, 1, "-p")
	table.insert(_args, 2, "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK")

	if options["chain-id"] then
		table.insert(_args, "--main-chain-id")
		table.insert(_args, options["chain-id"])
	end

	if options["hwm"] then
		table.insert(_args, "--main-hwm")
		table.insert(_args, options["hwm"])
	end

	log_info("Please confirm ledger authorization for baking...")
	local _proc = proc.spawn("bin/client", _args, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = path.combine(os.cwd(), "data") }
	})

	local _stderr = _proc.stderrStream:read("a")
	ami_assert(_proc.exitcode == 0 or not _stderr:match("Error:"),
		"Failed to setup ledger for baking: " .. (_stderr or ""))

	log_success("Ledger authorized for baking.")
end

return setup
