local _appId = am.app.get("id")

local _services = {
	[_appId .. "-xtz-signer"] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer.service")
}

local _nodeAddr = am.app.get_model("REMOTE_NODE")
if type(_nodeAddr) == "string" then
	local _signerTunnelId = am.app.get("id") .. "-xtz-signer-tunnel"
	_services[_signerTunnelId] = "__xtz/assets/signer-tunnel.service"
	local _nodeTunnelId = am.app.get("id") .. "-xtz-node-tunnel"
	_services[_nodeTunnelId] = "__xtz/assets/node-tunnel.service"
end

return _services