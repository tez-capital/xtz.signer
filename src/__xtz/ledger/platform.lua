local function add_udev_rules()
	local user = am.app.get("user", "root")
	ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

	local user_plugin, err = am.plugin.get("user")
	ami_assert(user_plugin, "failed to load user plugin: " .. tostring(err), EXIT_PLUGIN_LOAD_ERROR)

	ami_assert(user_plugin.add_into_group(user, "plugdev"), "failed to add user '" .. user .. "' to plugdev")

	local tmp_file_path = os.tmpname()
	local udev_rules_url =
	"https://raw.githubusercontent.com/alis-is/udev-rules/f15dc1eb83a4f3c666f58c12a93c45c6fca3a004/add_udev_rules.sh"
	local ok, error = net.download_file(udev_rules_url, tmp_file_path, { follow_redirects = true })
	if not ok then
		fs.remove(tmp_file_path)
		ami_error("failed to download: " .. tostring(error))
	end
	local process = proc.spawn("/bin/bash", { tmp_file_path }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = path.combine(os.cwd(), "data") }
	})

	fs.remove(tmp_file_path)
	ami_assert(process.exit_code == 0, "Failed to setup udev rules : " .. (process.stderr_stream:read("a") or "unknown"))
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
local platform_setups = {
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

	local setup = platform_setups[OS]
	if type(setup) == "function" then
		setup(options)
	else
		log_debug("No setup for platform: " .. OS .. " found. Skipping...")
	end

	log_success("Ledger platform setup completed.")
end

return setup
