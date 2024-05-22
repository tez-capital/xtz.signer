local _options = ...

local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local platform = am.app.get_model("PLATFORM")

if not _options["skip-udev"] or platform ~= "unix" then
	if not os.execute("which udevadm") then
		log_warn("udevadm not found. Skipping udev setup...")
	else
		-- Setup udev rules
		local _ok, _userPlugin = am.plugin.safe_get("user")
		if not _ok then
			log_error("Failed to load user plugin!")
			return
		end
		ami_assert(_userPlugin.add_into_group(_user, "plugdev"), "Failed to add user '" .. _user .. "' to plugdev")

		local _tmpFile = os.tmpname()
		local _udevRulesUrl =
		"https://raw.githubusercontent.com/alis-is/udev-rules/f15dc1eb83a4f3c666f58c12a93c45c6fca3a004/add_udev_rules.sh"
		local _ok, _error = net.safe_download_file(_udevRulesUrl, _tmpFile, { followRedirects = true })
		if not _ok then
			fs.remove(_tmpFile)
			ami_error("Failed to download: " .. tostring(_error))
		end
		local _proc = proc.spawn("/bin/bash", { _tmpFile }, {
			stdio = { stderr = "pipe" },
			wait = true,
			env = { HOME = path.combine(os.cwd(), "data") }
		})

		fs.remove(_tmpFile)
		ami_assert(_proc.exitcode == 0, "Failed to setup udev rules : " .. _proc.stderrStream:read("a"))
	end
end

local serviceManager = require "__xtz.service-manager"
local _services = require("__xtz.services")
local _ok, _status, _ = serviceManager.safe_get_service_status(_services.signerServiceId)

local _args = { "setup", "ledger", "to", "bake", "for", (_options.alias or "baker") }
if _ok and _status == "running" then
	table.insert(_args, 1, "--remote-signer")
	table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
end

if _options["main-chain-id"] then
	table.insert(_args, "--main-chain-id")
	table.insert(_args, _options["main-chain-id"])
end

if _options["main-hwm"] then
	table.insert(_args, "--main-hwm")
	table.insert(_args, _options["main-hwm"])
end

local _proc = proc.spawn("bin/client", _args, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})

local _stderr = _proc.stderrStream:read("a")
ami_assert(_proc.exitcode == 0 or not _stderr:match("Error:"), "Failed to setup ledger for baking: " .. (_stderr or ""))

log_success("Ledger setup successful.")
