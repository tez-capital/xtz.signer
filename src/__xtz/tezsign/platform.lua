local function add_udev_rules()
	local user = am.app.get("user", "root")
	ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)
	local tezsign_user = require "__xtz.tezsign.user".username

	local user_plugin, err = am.plugin.get("user")
	ami_assert(user_plugin, "failed to load user plugin: " .. tostring(err), EXIT_PLUGIN_LOAD_ERROR)

	ami_assert(user_plugin.add_into_group(user, "plugdev"), "failed to add user '" .. user .. "' to plugdev")
	ami_assert(user_plugin.add_into_group(tezsign_user, "plugdev"), "failed to add user '" .. tezsign_user .. "' to plugdev")

	local tmp_file_path = os.tmpname()
	local udev_rules_url =
	"https://raw.githubusercontent.com/tez-capital/tezsign/refs/heads/main/tools/add_udev_rules.sh"
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
	local system_distro = am.app.get_model("SYSTEM_DISTRO", "unknown")
	if not options["no-udev"] and system_distro ~= "MacOS" then
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
		log_debug("Skipping tezsign/platform setup...")
		return
	end

	local system_os = options["platform"]
	if system_os == "true" then
		log_trace("using autodetected platform")
		system_os = am.app.get_model("SYSTEM_OS", "unknown")
	end
	log_info("Configuring tezsign for platform: " .. tostring(system_os))

	local setup = platform_setups[system_os]
	if type(setup) == "function" then
		setup(options)
	else
		log_debug("No setup for platform: '" .. tostring(system_os) .. "' found. Skipping...")
	end

	log_success("Ledger tezsign setup completed.")
end

return setup
