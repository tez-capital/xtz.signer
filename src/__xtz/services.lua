local _appId = am.app.get("id")
local _signerServiceId = _appId .. "-xtz-signer"

local _possibleResidue = { }

local _signerServices = {
	[_signerServiceId] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer.service")
}


local _signerServiceNames = {}
for k, _ in pairs(_signerServices) do
	_signerServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end

local _allNames = util.clone(_signerServices)

local _tunnelServices = {}
local _tunnelServiceNames = {}
local _nodeAddr = am.app.get_model("REMOTE_NODE")
if type(_nodeAddr) == "string" then
	local _signerTunnelId = am.app.get("id") .. "-xtz-signer-tunnel"
	_tunnelServices[_signerTunnelId] = "__xtz/assets/signer-tunnel.service"
	local _nodeTunnelId = am.app.get("id") .. "-xtz-node-tunnel"
	_tunnelServices[_nodeTunnelId] = "__xtz/assets/node-tunnel.service"

	for k, _ in pairs(_signerServices) do
		_tunnelServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
		_allNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
	end
end

-- includes potential residues
local function _remove_all_services()
	local _all = util.merge_arrays(table.values(_signerServiceNames), table.values(_tunnelServices))
	_all = util.merge_arrays(_all, _possibleResidue)

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
	tunnelServices = _tunnelServices,
	tunnelServiceNames = _tunnelServiceNames,
	allNames = _allNames,
	remove_all_services = _remove_all_services
}