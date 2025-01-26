local ok, err = fs.safe_mkdirp("data")
ami_assert(ok, "Failed to create data directory - " .. tostring(err) .. "!")

local REMOTE_PRISM = am.app.get_configuration("PRISM")
if REMOTE_PRISM then
	require"__xtz.prism.setup"
end

local backend = am.app.get_configuration("backend", os.getenv("ASCEND_SERVICES") ~= nil and "ascend" or "systemd")
local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"
services.remove_all_services() -- cleanup past install

for k, v in pairs(services.all) do
	local service_id = k
	local source_file = string.interpolate("${file}.${extension}", {
		file = v,
		extension = backend == "ascend" and "ascend.hjson" or "service"
	})
	local ok, err = service_manager.safe_install_service(source_file, service_id)
	ami_assert(ok, "Failed to install " .. service_id .. ".service " .. (err or ""))
end

-- adjust data directory permissions
require"__xtz.util".reset_datadir_permissions()