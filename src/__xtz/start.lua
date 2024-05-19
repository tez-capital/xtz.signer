local serviceManager = require"__xtz.service-manager"
local services = require"__xtz.services"

for _, service in pairs(services.allNames) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = serviceManager.safe_start_service(service)
	ami_assert(_ok, "Failed to start " .. service .. ": " .. (_error or ""))
	::CONTINUE::
end

log_success("Signer services succesfully started.")