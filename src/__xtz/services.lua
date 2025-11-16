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
-- tezsign services
local tezsign_service_id = app_id .. "-tezsign"
local tezsign_services = {
	[tezsign_service_id] = "__xtz/assets/tezsign"
}
local tezsign_service_names = {}
for k, _ in pairs(tezsign_services) do
	tezsign_service_names[k:sub((#(app_id) + 2))] = k
end

local uses_remote = type(am.app.get_model("REMOTE_NODE")) == "string"
local uses_octez = am.app.get_configuration("BACKEND", "octez") == "octez"
local uses_prism = am.app.get_configuration({ "PRISM", "remote" }) or am.app.get_configuration({ "PRISM", "listen" })
local uses_tezsign = am.app.get_model("TEZSIGN_CONFIGURATION", nil) ~= nil

local tunnel_services =  uses_prism and prism_tunnel_services or ssh_tunnel_services
local tunnel_service_names = {}
for k, _ in pairs(tunnel_services) do
	tunnel_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
-- add not used tunnel services to possible residues
possible_residues = util.merge_arrays(possible_residues, uses_prism and table.keys(ssh_tunnel_services) or table.keys(prism_tunnel_services)) or {}
-- end tunnel services

local active_services = {}
local active_names = {}

if uses_octez then
	for k, v in pairs(signer_services) do
		active_services[k] = v
	end
	for k, v in pairs(signer_service_names) do
		active_names[k] = v
	end
end

if uses_remote or uses_prism then
	for k, v in pairs(tunnel_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(tunnel_services) do
		active_services[k] = v
	end
end

if uses_tezsign then
	for k, v in pairs(tezsign_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(tezsign_services) do
		active_services[k] = v
	end
end
--- cleanup names include everything including residues
---@type string[]
local cleanup_names = {}
cleanup_names = util.merge_arrays(cleanup_names, table.values(signer_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(tunnel_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(possible_residues))
cleanup_names = util.merge_arrays(cleanup_names, table.values(tezsign_service_names))

return {
	signer_service_id = signer_service_id,
	tezsign_service_id = tezsign_service_id,
	active = active_services,
	active_names = active_names,
	cleanup_names = cleanup_names,
}
