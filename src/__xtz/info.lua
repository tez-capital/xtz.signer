local _json = am.options.OUTPUT_FORMAT == "json"

local _options = ...
local _printServiceInfo = _options.services
local _printLedgerInfo = _options.ledger
local _printAll = (not _printLedgerInfo) and (not _printServiceInfo)

local ANALYTICS_URL = "https://analytics.tez.capital/bake"

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _info = {
	level = "ok",
	status = "Signer is operational",
	ledger = "not found",
	version = am.app.get_version(),
	type = am.app.get_type(),
	services = {}
}

if _printAll or _printServiceInfo then
	local _services = require "__xtz.services"
	for k, v in pairs(_services.allNames) do
		if type(v) ~= "string" then goto CONTINUE end
		local _ok, _status, _started = _systemctl.safe_get_service_status(v)
		ami_assert(_ok, "Failed to get status of " .. v .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)
		_info.services[k] = {
			status = _status,
			started = _started
		}
		-- // TODO: remove from root object after migration to bb-cli next
		_info[k] = _status
		_info[k .. "_started"] = _started
		if _status ~= "running" then
			_info.status = "One or more signer services is not running!"
			_info.level = "error"
		end
		::CONTINUE::
	end
end

local _homedir = path.combine(os.cwd(), "data")

local _ok, _pubKeysFile = fs.safe_read_file("./data/.tezos-signer/public_key_hashs")
if _ok then
	local _ok, _pubKeys = hjson.safe_parse(_pubKeysFile)
	if _ok then
		for _, _pubKeyRecord in ipairs(_pubKeys) do
			if _pubKeyRecord["name"] == "baker" then
				_info.baker_address = _pubKeyRecord["value"]

				if _info.baker_address and os.getenv("DISABLE_TEZBAKE_ANALYTICS") ~= "true" and am.app.get_configuration("DISABLE_ANALYTICS", false) ~= true then
					local _analyticsCmd = string.interpolate(
						[[net.RestClient:new("${ANALYTICS_URL}", { timeout = 60 }):safe_post({ bakerId = "${bakerId}", version = "${version}" }); os.exit(0);]],
						{ bakerId = _info.baker_address, version = am.app.get_version(), ANALYTICS_URL = ANALYTICS_URL }
					)
					proc.spawn("eli", { "-e", _analyticsCmd }, {wait = false, stdio = "ignore"})
				end
				break
			end
		end
	end
end

if _printAll or _printLedgerInfo then
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
		if ver.compare(_bakingAppVer, "2.2.15") < 0 and _info.status ~= "error" then
			_info.status = "error"
			_info.status = "ledger baking app too old"
		elseif ver.compare(_bakingAppVer, "2.3.2") < 0 and _info.status ~= "error" then
			_info.status = "warning"
			_info.status = "Ledger baking app is not latest available"
		end
	end
end

if _json then
	print(hjson.stringify_to_json(_info, { indent = false }))
else
	print(hjson.stringify(_info, { sortKeys = true }))
end
