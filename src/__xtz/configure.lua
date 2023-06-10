local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _ok, _error = fs.safe_mkdirp("data")
ami_assert(_ok, "Failed to create data directory - " .. tostring(_error) .. "!")
local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

-- Setup ledger
local _ok, _userPlugin = am.plugin.safe_get("user")
if not _ok then
    log_error("Failed to load user plugin!")
    return
end
ami_assert(_userPlugin.add_into_group(_user, "plugdev"), "Failed to add user '" .. _user .. "' to plugdev")

local _tmpFile = os.tmpname()
local _udevRulesUrl = "https://raw.githubusercontent.com/alis-is/udev-rules/f15dc1eb83a4f3c666f58c12a93c45c6fca3a004/add_udev_rules.sh"
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
-- ami_assert(os.execute("udevadm trigger"), "Failed to run 'udevadm trigger'!")
-- ami_assert(os.execute("udevadm control --reload-rules"), "Failed to run 'udevadm control --reload-rules'!")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _services = require"__xtz.services"
_services.remove_all_services() -- cleanup past install

for serviceId, serviceFile in pairs(_services.signer) do
	local _ok, _error = _systemctl.safe_install_service(serviceFile, serviceId)
	ami_assert(_ok, "Failed to install " .. serviceId .. ".service " .. (_error or ""))
end

for serviceId, serviceFile in pairs(_services.tunnelServices) do
	local _ok, _error = _systemctl.safe_install_service(serviceFile, serviceId)
	ami_assert(_ok, "Failed to install " .. serviceId .. ".service " .. (_error or ""))
end

log_info("Granting access to " .. _user .. "(" .. tostring(_uid) .. ")...")
local _ok, _error = fs.chown(os.cwd(), _uid, _uid, {recurse = true})
ami_assert(_ok, "Failed to chown data - " .. (_error or ""))