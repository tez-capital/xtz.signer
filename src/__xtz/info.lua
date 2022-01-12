local _json = am.options.OUTPUT_FORMAT == "json"
local _appId = am.app.get("id", "unknown")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _info = {
    level = "ok",
    status = "Signer is operational",
	ledger = "not found",
    version = am.app.get_version(),
    type = am.app.get_type()
}

local _services = require"__xtz.services"

local _tunnels = am.app.get_configuration("TUNNELS", {})
if type(_tunnels) == "table" and not table.is_array(_tunnels) then
	for tunnelId, _ in pairs(_tunnels) do
		local _tunnelServiceId = am.app.get("id") .. "-xtz-tunnel-" .. tunnelId
		table.insert(_services, _tunnelServiceId)
	end
end

for serviceId, _ in pairs(_services) do
	if type(serviceId) ~= "string" then goto CONTINUE end
	local _serviceAlias = serviceId:sub(#_appId + 2) -- strip appId
	local _ok, _status, _started = _systemctl.safe_get_service_status(serviceId)
	ami_assert(_ok, "Failed to get status of " .. serviceId .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)
	_info[_serviceAlias] = _status
	_info[_serviceAlias .. "_started"] = _started
	if _status ~= "running" then
		_info.status = "One or more signer services is not running!"
		_info.level = "error"
	end
	::CONTINUE::
end

local _user = am.app.get("user", "root")
local _homedir = path.combine(os.cwd(), "data")

local _ok, _pubKeysFile = fs.safe_read_file("./data/.tezos-signer/public_key_hashs")
if _ok then
	local _ok, _pubKeys = hjson.safe_parse(_pubKeysFile)
	if _ok then
		for _, _pubKeyRecord in ipairs(_pubKeys) do
			if _pubKeyRecord["name"] == "baker" then
				_info.baker_address = _pubKeyRecord["value"]
				break
			end
		end
	end
end

local _args = { "list", "connected", "ledgers" }
if _info.signer == "running" then
	table.insert(_args, 1, "--remote-signer")
	table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT"))
end
local _proc = proc.spawn("bin/client", _args, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = _homedir }
})

local _output = _proc.exitcode == 0 and _proc.stdoutStream:read("a") or "failed"
local _legerId = _output:match("## Ledger `(.-)`")
local _bakingAppVer = _output:match("Found a Tezos Baking (%S*)")
local _bakingAppRunning = _output:match("Found a Tezos Baking .* running%s*on")
if not _legerId then
	_info.status = "No ledger device found!"
	_info.level = "error"
elseif not _bakingAppRunning or not _bakingAppVer then
	_info.status = "Baking app not found or not running!"
	_info.ledger = "connected"
	_info.level = "error"
else
	_info.ledger_id = _legerId
	_info.ledger = "connected"
	_info.baking_app = _bakingAppVer
	_info.baking_app_status = "running"
	if not _info.baker_address then
		_info.status = "Baker key not found! Please import it..."
		_info.level = "error"
	else
		-- TODO: return baker addr and check if authorized
		local _args = { "get", "ledger", "authorized", "path", "for", "baker" }
		if _info.signer == "running" then
			table.insert(_args, 1, "--remote-signer")
			table.insert(_args, 2, "http://" .. am.app.get_model("SIGNER_ADDR") .. am.app.get_model("SIGNER_PORT")) 
		end
		local _proc = proc.spawn("bin/client", _args, {
			stdio = { stderr = "pipe" },
			wait = true,
			env = { HOME = _homedir }
		})
		local _output = _proc.exitcode == 0 and _proc.stdoutStream:read("a") or "failed"
		if not _output:match("Authorized baking") then
			_info.status = "Baker key not authorized! Please setup ledger for baking..."
			_info.level = "error"
		end
	end
end

if _json then
    print(hjson.stringify_to_json(_info, {indent = false}))
else
    print(hjson.stringify(_info, {sortKeys = true}))
end