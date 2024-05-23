local _ok, _error = fs.safe_mkdirp("data")
ami_assert(_ok, "Failed to create data directory - " .. tostring(_error) .. "!")

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

-- adjust data directory permissions
require"__xtz.util".reset_datadir_permissions()