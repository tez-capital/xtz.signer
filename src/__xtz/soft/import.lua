-- import secret key <alias> <key
-- ami setup-soft-wallet --import-key <derivation-path> --key-alias <alias> --force

---@param options table<string, any>
local function setup(options)
	log_info("Importing soft-wallet key key...")

	local homedir = path.combine(os.cwd(), "data")

	local serviceManager = require "__xtz.service-manager"
	local services = require "__xtz.services"
	local ok, status, _ = serviceManager.safe_get_service_status(services.signerServiceId)
	ami_assert(ok and status ~= "running", services.signerServiceId .. " is already running. Please stop it to import keys...",
		EXIT_APP_INTERNAL_ERROR)

	local key = options["import-key"]
    ami_assert(type(key) == "string", "Invalid key detected!", EXIT_CLI_ARG_VALIDATION_ERROR)

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	local _proc = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", key,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir }
		})
	ami_assert(_proc.exitcode == 0, "Failed to import key to signer!")

	local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
	if type(options.protocol) == "string" then
		protocol = options.protocol
	end

	local _proc = proc.spawn("bin/client",
		{ "-p", protocol, "import", "secret", "key", alias or "baker", key,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir }
		})
	ami_assert(_proc.exitcode == 0, "Failed to import key to client!")

	log_success("Soft-wallet key successfully imported.")
end

return setup