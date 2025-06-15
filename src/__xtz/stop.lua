local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

log_info("stopping signer services... this may take few minutes.")

service_manager.stop_services(services.active_names)

log_success("signer services successfully stopped.")