local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _toStop = table.keys(require"__xtz.services")

local _tunnels = am.app.get_configuration("TUNNELS", {})
if type(_tunnels) == "table" and not table.is_array(_tunnels) then
	for tunnelId, _ in pairs(_tunnels) do
		local _tunnelServiceId = am.app.get("id") .. "-xtz-tunnel-" .. tunnelId
		table.insert(_toStop, _tunnelServiceId)
	end
end

for _, service in ipairs(_toStop) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = _systemctl.safe_stop_service(service)
	ami_assert(_ok, "Failed to stop " .. service .. ".service " .. (_error or ""))
	::CONTINUE::
end
log_success("Signer services succesfully stopped.")