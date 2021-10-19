local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

-- Setup ledger
local _tmpFile = os.tmpname()
local _udevRulesUrl = "https://raw.githubusercontent.com/LedgerHQ/udev-rules/709581c85db97bf6ea12e472aa4e350bf0eabfb7/add_udev_rules.sh"
local _ok, _error = net.safe_download_file(_udevRulesUrl, _tmpFile, {followRedirects = true})
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
ami_assert(os.execute("udevadm trigger"), "Failed to run 'udevadm trigger'!")
ami_assert(os.execute("udevadm control --reload-rules"), "Failed to run 'udevadm control --reload-rules'!")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _signerServiceId = am.app.get("id") .. "-xtz-signer"
local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/signer.service"), _signerServiceId)
ami_assert(_ok, "Failed to install " .. _signerServiceId .. ".service " .. (_error or ""))

local _tunnels = am.app.get_configuration("TUNNELS", {})
if type(_tunnels) == "table" and not table.is_array(_tunnels) then
	for tunnelId, addr in pairs(_tunnels) do
		local _tunnelServiceId = am.app.get("id") .. "-xtz-tunnel-" .. tunnelId
		local _template = fs.read_file("__xtz/assets/tunnel.service")
		local _subService = _template:gsub("<<<BAKER_NODE_ADDR>>>", addr, 1)
		fs.write_file("__xtz/assets/" .. tunnelId .. ".service", _subService)
		_ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/" .. tunnelId .. ".service"), _tunnelServiceId)
		ami_assert(_ok, "Failed to install " .. _tunnelServiceId .. ".service " .. (_error or ""))
	end
end