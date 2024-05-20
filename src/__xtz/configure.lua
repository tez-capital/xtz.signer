local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _ok, _error = fs.safe_mkdirp("data")
ami_assert(_ok, "Failed to create data directory - " .. tostring(_error) .. "!")
local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

local backend = am.app.get_configuration("backend", os.getenv("ASCEND_SERVICES") ~= nil and "ascend" or "systemd")
local serviceManager = require"__xtz.service-manager"
local services = require"__xtz.services"
services.remove_all_services() -- cleanup past install

for k, v in pairs(services.all) do
	local _serviceId = k
	local sourceFile = string.interpolate("${file}.${extension}", {
		file = v,
		extension = backend == "ascend" and "ascend.hjson" or "service"
	})
	local _ok, _error = serviceManager.safe_install_service(sourceFile, _serviceId)
	ami_assert(_ok, "Failed to install " .. _serviceId .. ".service " .. (_error or ""))
end

log_info("Granting access to " .. _user .. "(" .. tostring(_uid) .. ")...")
local _ok, _error = fs.chown(os.cwd(), _uid, _uid, {recurse = true})
ami_assert(_ok, "Failed to chown data - " .. (_error or ""))