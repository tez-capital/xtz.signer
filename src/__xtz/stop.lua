local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

log_info("Stopping signer services... this may take few minutes.")
for _, service in pairs(services.all_names) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = service_manager.safe_stop_service(service)
	ami_assert(_ok, "Failed to stop " .. service .. ": " .. (_error or ""))
	::CONTINUE::
end
log_success("Signer services succesfully stopped.")