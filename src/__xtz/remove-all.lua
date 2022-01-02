local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _isBaker = am.app.get_configuration("NODE_TYPE") == "baker"

local _toRemove = table.keys(require"__xtz.services")

local _tunnels = am.app.get_configuration("TUNNELS", {})
if type(_tunnels) == "table" and not table.is_array(_tunnels) then
	for tunnelId, _ in pairs(_tunnels) do
		local _tunnelServiceId = am.app.get("id") .. "-xtz-tunnel-" .. tunnelId
		table.insert(_toRemove, _tunnelServiceId)
	end
end

for _, service in ipairs(_toRemove) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = _systemctl.safe_remove_service(service)
	if not _ok then
		ami_error("Failed to remove " .. service .. ".service " .. (_error or ""))
	end
	::CONTINUE::
end

log_success("Node services succesfully removed.")