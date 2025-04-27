local app_id = am.app.get("id")
local signer_service_id = app_id .. "-xtz-signer"

local possible_residues = {
	app_id .. "-xtz-prism-tunnel"
}

-- signer services
local signer_services = {
	[signer_service_id] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer")
}
local signer_service_names = {}
for k, _ in pairs(signer_services) do
	signer_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
-- end signer services

-- tunnel services
local ssh_tunnel_services = {
	[app_id .. "-xtz-signer-tunnel"] = "__xtz/assets/signer-tunnel",
	[app_id .. "-xtz-node-tunnel"] = "__xtz/assets/node-tunnel"
}
local prism_tunnel_services = {
	[app_id .. "-xtz-prism"] = "__xtz/assets/prism"
}

local uses_prism = am.app.get_configuration("PRISM")
local tunnel_services =  uses_prism and prism_tunnel_services or ssh_tunnel_services
local tunnel_service_names = {}
for k, _ in pairs(tunnel_services) do
	tunnel_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
-- add not used tunnel services to possible residues
possible_residues = util.merge_arrays(possible_residues, uses_prism and table.keys(ssh_tunnel_services) or table.keys(prism_tunnel_services)) or {}
-- end tunnel services

local all = util.clone(signer_services)
local all_names = util.clone(signer_service_names)

local remote_node_addr = am.app.get_model("REMOTE_NODE")
if type(remote_node_addr) == "string" then
	for k, v in pairs(tunnel_service_names) do
		all_names[k] = v
	end
	for k, v in pairs(tunnel_services) do
		all[k] = v
	end
end

-- includes potential residues
local function remove_all_services()
	local service_manager = require"__xtz.service-manager"

	local all = util.merge_arrays(table.values(signer_service_names), table.values(tunnel_service_names))
	all = util.merge_arrays(all, possible_residues)

	for _, service in ipairs(all) do
		if type(service) ~= "string" then goto CONTINUE end
		local ok, rtt = service_manager.safe_remove_service(service)
		if not ok then
			ami_error("Failed to remove " .. service .. ": " .. (rtt or ""))
		end
		::CONTINUE::
	end
end

return {
	signer_service_id = signer_service_id,
	all = all,
	all_names = all_names,
	signer_service_names = signer_service_names,
	remove_all_services = remove_all_services
}
