local _appId = am.app.get("id")
local _signerServiceId = _appId .. "-xtz-signer"

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

return {
	signerServiceId = _signerServiceId,
	signer = _signerServices,
	signerServiceNames = _signerServiceNames
}