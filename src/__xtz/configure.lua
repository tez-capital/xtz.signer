local ok, err = fs.mkdirp("data")
ami_assert(ok, "failed to create data directory - " .. tostring(err))

local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"
service_manager.remove_services(services.cleanup_names) -- cleanup past install
service_manager.install_services(services.active)
log_success(am.app.get("id") .. " services configured")

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then require"__xtz.prism.setup" end

-- adjust data directory permissions
require"__xtz.base_utils".setup_file_ownership()