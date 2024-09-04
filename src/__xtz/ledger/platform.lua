local platform = am.app.get_model("PLATFORM")

local function add_udev_rules()
	local user = am.app.get("user", "root")
	ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

	local ok, userPlugin = am.plugin.safe_get("user")
	if not ok then
		log_error("Failed to load user plugin!")
		return
	end
	ami_assert(userPlugin.add_into_group(user, "plugdev"), "Failed to add user '" .. user .. "' to plugdev")

	local tmpFile = os.tmpname()
	local udevRulesUrl =
	"https://raw.githubusercontent.com/alis-is/udev-rules/f15dc1eb83a4f3c666f58c12a93c45c6fca3a004/add_udev_rules.sh"
	local ok, error = net.safe_download_file(udevRulesUrl, tmpFile, { followRedirects = true })
	if not ok then
		fs.remove(tmpFile)
		ami_error("Failed to download: " .. tostring(error))
	end
	local _proc = proc.spawn("/bin/bash", { tmpFile }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = path.combine(os.cwd(), "data") }
	})

	fs.remove(tmpFile)
	ami_assert(_proc.exitcode == 0, "Failed to setup udev rules : " .. (_proc.stderrStream:read("a") or "unknown"))
	log_info("udev rules setup completed")
end

---@param options table<string, any>
local function setup_linux(options)
	if not options["no-udev"] then
		if os.execute("which udevadm > /dev/null") then
			add_udev_rules()
		else
			ami_error("udevadm not found. Cannot setup udev rules... (use --no-udev to skip)")
		end
	end
end

---@type {table<string, fun(options: table<string, any>)>}
local platformSetups = {
	unix = setup_linux,
	linux = setup_linux,
}

---@param options table<string, any>
local function setup(options)
	if not options["platform"] then
		log_debug("Skipping ledger/platform setup...")
		return
	end

	local OS = options["platform"]
	if OS == "true" then
		log_info("Platform not specified. Detecting...")
		local platform = am.app.get_model("PLATFORM")
		OS = platform.OS
	end
	log_info("Configuring ledger for platform: " .. OS)

	local setup = platformSetups[OS]
	if type(setup) == "function" then
		setup(options)
	else
		log_debug("No setup for platform: " .. OS .. " found. Skipping...")
	end

	log_success("Ledger platform setup completed.")
end

return setup
