local tezsign_configuration = require("__xtz.tezsign.configuration")
local homedir = path.combine(os.cwd(), "data")


local tezsign_service_id = require("__xtz.services").tezsign_service_id
local function is_tezsign_running()
	local service_manager = require "__xtz.service-manager"
	local status, all_running = service_manager.get_services_status({ tezsign_service_id })
	-- status has to contain the tezsign service and it has to be running
	-- we could get status without it if it is not installed
	-- but all running would still be true in that case
	return status[tezsign_service_id] and all_running == true
end


local function get_devices()
	local process = proc.spawn("bin/tezsign", { "list-devices" }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = homedir }
	})

	ami_assert(process.exit_code == 0,
		"Failed to get connected devices: " .. (process.stderr_stream:read("a") or "unknown"))
	local output = process.stdout_stream:read("a") or ""
	-- json: [{"Serial":"444F57BB6DD642A29FC6B6B0F0222117","Manufacturer":"TzC","Product":"tezsign-gadget"}]
	local devices = hjson.parse(output)
	ami_assert(type(devices) == "table" and #devices > 0, "No connected devices found!", EXIT_APP_INTERNAL_ERROR)
	return devices
end

local function resolve_tezsign_key(device, alias)
	local process = proc.spawn("bin/tezsign", { "--device", device, "list" }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = homedir }
	})

	ami_assert(process.exit_code == 0,
		"Failed to get connected devices: " .. (process.stderr_stream:read("a") or "unknown"))
	local output = process.stdout_stream:read("a") or ""
	-- json: {"baker":"tz4PLVFDLuEmzEP658FbXoDdggNRWe25ZgaZ","consensus":"tz4U2MAESy9qsbyBzfYWp4QWGxcBcftQqP5T"}
	local keys = hjson.parse(output)
	ami_assert(type(keys) == "table" and keys[alias], "Failed to resolve key for alias: " .. tostring(alias),
		EXIT_APP_INTERNAL_ERROR)
	return keys[alias]
end

---@param options table<string, any>
local function setup(options)
	if not options["import-key"] then
		log_debug("No key import specified. Skipping tezsign/key setup...")
		return
	end

	local key_id = options["import-key"]
	if type(key_id) ~= "string" then
		key_id = "baker"
		log_info("No key alias specified. Using default alias: 'baker'")
	end

	log_info("Importing tezsign key...")

	-- local service_manager = require "__xtz.service-manager"
	-- local services = require "__xtz.services"
	-- ami_assert(not service_manager.have_all_services_status({ services.signer_service_id }, "running"),
	-- 	services.signer_service_id .. " is already running. Please stop it to import keys...",
	-- 	EXIT_APP_INTERNAL_ERROR)


	local device_id = options["device-id"]
	if type(device_id) ~= "string" then
		log_info("Device id not specified. Looking up connected devices...")
		local devices = get_devices()
		device_id = devices[1].Serial
		log_info("Using device id: " .. device_id)
	end
	ami_assert(type(device_id) == "string", "Failed to get ledger id!")


	local tz4 = resolve_tezsign_key(device_id, key_id)
	assert(type(tz4) == "string" and tz4:match("^tz4"), "Failed to resolve tezsign key " .. tostring(key_id) .. "!",
		EXIT_APP_INTERNAL_ERROR)

	local listen = tezsign_configuration.listen
	-- we need close to stop the tezsign server after import
	assert(is_tezsign_running() == true,
		"tezsign service is not running. Please start it to import keys!",
		EXIT_APP_INTERNAL_ERROR)

	local alias = "baker"
	if options["key-alias"] then
		alias = options["key-alias"]
		ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
	end

	-- listen with the tezsign in the background
	local process = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", "http://" .. listen .. "/" .. tz4,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir, OPENSSL_CONF = "/dev/null" }
		})
	ami_assert(process.exit_code == 0, "Failed to import key to signer!")

	local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
	if type(options.protocol) == "string" then
		protocol = options.protocol
	end

	log_info("Please confirm key import for client...")
	local process = proc.spawn("bin/client",
		{ "-p", protocol, "import", "secret", "key", alias or "baker", "http://" .. listen .. "/" .. tz4,
			options.force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir, OPENSSL_CONF = "/dev/null" }
		})
	ami_assert(process.exit_code == 0, "Failed to import key to client!")

	log_success("tezsign key successfully imported.")
end

return setup
