---@param options table<string, any>
local function setup(options)
	if not options["import-key"] then
		log_debug("No key import specified. Skipping ledger/key setup...")
		return
	end

	log_info("Importing ledger key...")

	local homedir = path.combine(os.cwd(), "data")

	local service_manager = require "__xtz.service-manager"
	local services = require "__xtz.services"
	ami_assert(not service_manager.have_all_services_status({ services.signer_service_id }, "running"),
		services.signer_service_id .. " is already running. Please stop it to import keys...",
		EXIT_APP_INTERNAL_ERROR)


	local ledger_id = options["ledger-id"]
	if type(ledger_id) ~= "string" then
		log_info("Ledger id not specified. Looking up connected ledgers...")
		local process = proc.spawn("bin/client", { "list", "connected", "ledgers" }, {
			stdio = { stderr = "pipe" },
			wait = true,
			env = { HOME = homedir },
			username = am.app.get("user"),
		})

		ami_assert(process.exit_code == 0,
		"Failed to get connected ledgers: " .. (process.stderr_stream:read("a") or "unknown"))
		local output = process.stdout_stream:read("a") or ""
		ledger_id = output:match("## Ledger `(.-)`")
		ami_assert(ledger_id, "No connected ledgers found!", EXIT_APP_INTERNAL_ERROR)
		log_info("Using ledger id: " .. ledger_id)
	end
	ami_assert(type(ledger_id) == "string", "Failed to get ledger id!")

	local derivation_path = options["import-key"]
	if type(derivation_path) ~= "string" then
		log_debug("Invalid derivation path detected. Using the default - 'ed25519/0h/0h'.")
		derivation_path = "ed25519/0h/0h"
	end

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	log_info("Please confirm key import for signer...")
	local process = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", "ledger://" .. ledger_id .. "/" .. derivation_path,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir },
			username = am.app.get("user"),
		})
	ami_assert(process.exit_code == 0, "Failed to import key to signer!")

	local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
	if type(options.protocol) == "string" then
		protocol = options.protocol
	end

	log_info("Please confirm key import for client...")
	local process = proc.spawn("bin/client",
		{ "-p", protocol, "import", "secret", "key", alias or "baker", "ledger://" .. ledger_id .. "/" .. derivation_path,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir },
			username = am.app.get("user"),
		})
	ami_assert(process.exit_code == 0, "Failed to import key to client!")

	log_success("Ledger key successfully imported.")
end

return setup
