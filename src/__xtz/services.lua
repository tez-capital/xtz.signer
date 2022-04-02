local _appId = am.app.get("id")
local _signerServiceId = _appId .. "-xtz-signer"

local _possibleResidue = { }

local _signerServices = {
	[_signerServiceId] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer.service")
}

local _nodeAddr = am.app.get_model("REMOTE_NODE")
if type(_nodeAddr) == "string" then
	local _signerTunnelId = am.app.get("id") .. "-xtz-signer-tunnel"
	_signerServices[_signerTunnelId] = "__xtz/assets/signer-tunnel.service"
	local _nodeTunnelId = am.app.get("id") .. "-xtz-node-tunnel"
	_signerServices[_nodeTunnelId] = "__xtz/assets/node-tunnel.service"
end

local _signerServiceNames = {}
for k, _ in pairs(_signerServices) do
	_signerServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end

-- includes potential residues
local function _remove_all_services()
	local _all = util.merge_arrays(table.values(_signerServiceNames), _possibleResidue)
	local _ok, _systemctl = am.plugin.safe_get("systemctl")
	ami_assert(_ok, "Failed to load systemctl plugin")

	for _, service in ipairs(_all) do
		if type(service) ~= "string" then goto CONTINUE end
		local _ok, _error = _systemctl.safe_remove_service(service)
		if not _ok then
			ami_error("Failed to remove " .. service .. ".service " .. (_error or ""))
		end
		::CONTINUE::
	end
end

return {
	signerServiceId = _signerServiceId,
	signer = _signerServices,
	signerServiceNames = _signerServiceNames,
	remove_all_services = _remove_all_services
}