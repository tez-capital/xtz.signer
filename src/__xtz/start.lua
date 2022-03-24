local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _services = require"__xtz.services"

for _, service in pairs(_services.signerServiceNames) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = _systemctl.safe_start_service(service)
	ami_assert(_ok, "Failed to start " .. service .. ".service " .. (_error or ""))
	::CONTINUE::
end

log_success("Signer services succesfully started.")