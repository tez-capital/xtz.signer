local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _toRemove = table.keys(require"__xtz.services")

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