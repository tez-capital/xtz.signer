local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

service_manager.start_services(services.active_names)

log_success("signer services successfully started.")