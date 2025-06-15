-- import secret key <alias> <key
-- ami setup-soft-wallet --import-key <derivation-path> --key-alias <alias> --force

---@param options table<string, any>
local function setup(options)
	log_info("Importing soft-wallet key key...")

	local homedir = path.combine(os.cwd(), "data")

	local service_manager = require "__xtz.service-manager"
	local services = require "__xtz.services"
	ami_assert(not service_manager.have_all_services_status({ services.signer_service_id }, "running"),
		services.signer_service_id .. " is already running. Please stop it to import keys...",
		EXIT_APP_INTERNAL_ERROR)

	local key = options["import-key"]
    ami_assert(type(key) == "string", "Invalid key detected!", EXIT_CLI_ARG_VALIDATION_ERROR)

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	local process = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", key,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir }
		})
	ami_assert(process.exit_code == 0, "Failed to import key to signer!")

	local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
	if type(options.protocol) == "string" then
		protocol = options.protocol
	end

	local process = proc.spawn("bin/client",
		{ "-p", protocol, "import", "secret", "key", alias or "baker", key,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir }
		})
	ami_assert(process.exit_code == 0, "Failed to import key to client!")

	log_success("Soft-wallet key successfully imported.")
end

return setup