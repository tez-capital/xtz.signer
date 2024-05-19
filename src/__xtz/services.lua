local appId = am.app.get("id")
local signerServiceId = appId .. "-xtz-signer"

local possibleResidue = {}

local signerServices = {
	[signerServiceId] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer")
}
local tunnelServices = {
	[appId .. "-xtz-signer-tunnel"] = "__xtz/assets/signer-tunnel",
	[appId .. "-xtz-node-tunnel"] = "__xtz/assets/node-tunnel"
}

local signerServiceNames = {}
for k, _ in pairs(signerServices) do
	signerServiceNames[k:sub((#(appId .. "-xtz-") + 1))] = k
end

local tunnelServiceNames = {}
for k, _ in pairs(tunnelServices) do
	tunnelServiceNames[k:sub((#(appId .. "-xtz-") + 1))] = k
end

local all = util.clone(signerServices)
local allNames = util.clone(signerServiceNames)

local nodeAddr = am.app.get_model("REMOTE_NODE")
if type(nodeAddr) == "string" then
	for k, v in pairs(tunnelServiceNames) do
		allNames[k] = v
	end
	for k, v in pairs(tunnelServices) do
		all[k] = v
	end
end

-- includes potential residues
local function _remove_all_services()
	local serviceManager = require"__xtz.service-manager"

	local all = util.merge_arrays(table.values(signerServiceNames), table.values(tunnelServices))
	all = util.merge_arrays(all, possibleResidue)

	for _, service in ipairs(all) do
		if type(service) ~= "string" then goto CONTINUE end
		local _ok, _error = serviceManager.safe_remove_service(service)
		if not _ok then
			ami_error("Failed to remove " .. service .. ": " .. (_error or ""))
		end
		::CONTINUE::
	end
end

return {
	signerServiceId = signerServiceId,
	all = all,
	allNames = allNames,
	signerServiceNames = signerServiceNames,
	remove_all_services = _remove_all_services
}
