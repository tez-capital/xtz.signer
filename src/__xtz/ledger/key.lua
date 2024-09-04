---@param options table<string, any>
local function setup(options)
	if not options["import-key"] then
		log_debug("No key import specified. Skipping ledger/key setup...")
		return
	end

	log_info("Importing ledger key...")

	local homedir = path.combine(os.cwd(), "data")

	local serviceManager = require "__xtz.service-manager"
	local services = require "__xtz.services"
	local ok, status, _ = serviceManager.safe_get_service_status(services.signerServiceId)
	ami_assert(ok and status ~= "running", services.signerServiceId .. " is already running. Please stop it to import keys...",
		EXIT_APP_INTERNAL_ERROR)


	local ledgerId = options["ledger-id"]
	if type(ledgerId) ~= "string" then
		log_info("Ledger id not specified. Looking up connected ledgers...")
		local _proc = proc.spawn("bin/client", { "list", "connected", "ledgers" }, {
			stdio = { stderr = "pipe" },
			wait = true,
			env = { HOME = homedir }
		})

		ami_assert(_proc.exitcode == 0, "Failed to get connected ledgers: " .. (_proc.stderrStream:read("a") or "unknown"))
		local _output = _proc.stdoutStream:read("a")
		ledgerId = _output:match("## Ledger `(.-)`")
		ami_assert(ledgerId, "No connected ledgers found!", EXIT_APP_INTERNAL_ERROR)
		log_info("Using ledger id: " .. ledgerId)
	end
	ami_assert(type(ledgerId) == "string", "Failed to get ledger id!")

	local derivationPath = options["import-key"]
	if type(derivationPath) ~= "string" then
		log_debug("Invalid derivation path detected. Using the default - 'ed25519/0h/0h'.")
		derivationPath = "ed25519/0h/0h"
	end

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	log_info("Please confirm key import for signer...")
	local _proc = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", "ledger://" .. ledgerId .. "/" .. derivationPath,
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


	log_info("Please confirm key import for client...")
	local _proc = proc.spawn("bin/client",
		{ "-p", protocol, "import", "secret", "key", alias or "baker", "ledger://" .. ledgerId .. "/" .. derivationPath,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir }
		})
	ami_assert(_proc.exitcode == 0, "Failed to import key to client!")

	log_success("Ledger key successfully imported.")
end

return setup
