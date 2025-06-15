---@param options table<string, any>
local function setup(options)
	if not options["authorize"] then
		log_debug("Skipping ledger/authorize setup...")
		return
	end

	log_info("Authorizing ledger for baking...")

	local service_manager = require "__xtz.service-manager"
	local services = require("__xtz.services")
	local is_signer_running = service_manager.have_all_services_status({services.signer_service_id}, "running")

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	local args = { "setup", "ledger", "to", "bake", "for", alias }
	if is_signer_running then
		table.insert(args, 1, "--remote-signer")
		table.insert(args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
	end

	local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
	if type(options.protocol) == "string" then
		protocol = options.protocol
	end
	table.insert(args, 1, "-p")
	table.insert(args, 2, protocol)

	if options["chain-id"] then
		table.insert(args, "--main-chain-id")
		table.insert(args, options["chain-id"])
	end

	if options["hwm"] then
		table.insert(args, "--main-hwm")
		table.insert(args, options["hwm"])
	end

	log_info("Please confirm ledger authorization for baking...")
	local process = proc.spawn("bin/client", args, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = path.combine(os.cwd(), "data") }
	})

	local stderr = process.stderr_stream:read("a") or ""
	ami_assert(process.exit_code == 0 or not stderr:match("Error:"),
		"Failed to setup ledger for baking: " .. stderr)

	log_success("Ledger authorized for baking.")
end

return setup
