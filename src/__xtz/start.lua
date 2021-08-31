local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _toStart = {
	am.app.get("id") .. "-xtz-signer"
}

local _tunnels = am.app.get_configuration("TUNNELS", {})
if type(_tunnels) == "table" and not table.is_array(_tunnels) then
	for tunnelId, _ in pairs(_tunnels) do
		local _tunnelServiceId = am.app.get("id") .. "-xtz-tunnel-" .. tunnelId
		table.insert(_toStart, _tunnelServiceId)
	end
end

for _, service in ipairs(_toStart) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = _systemctl.safe_start_service(service)
	ami_assert(_ok, "Failed to start " .. service .. ".service " .. (_error or ""))
	::CONTINUE::
end

log_success("Signer services succesfully started.")