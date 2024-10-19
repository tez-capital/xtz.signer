local _json = am.options.OUTPUT_FORMAT == "json"

local _options = ...
local _printServiceInfo = _options.services
local print_wallet_info = _options.wallets
local is_sensitive_mode = _options["sensitive"]
local _skipLedgerAuthorizationCheck = _options["skip-authorization-check"]
local _printAll = (not print_wallet_info) and (not _printServiceInfo)

local _homedir = path.combine(os.cwd() or ".", "data")

local _info = {
	level = "ok",
	status = "Signer is operational",
	wallets = {},
	version = am.app.get_version(),
	type = am.app.get_type(),
	services = {}
}

local function set_status(level, status)
	if _info.level == "ok" then
		_info.level = level
		_info.status = status
	end
	if _info.level == "warning" and level == "error" then
		_info.level = level
		_info.status = status
	end
end

local function send_analytics(address)
	if os.getenv("DISABLE_TEZBAKE_ANALYTICS") == "true" or am.app.get_configuration("DISABLE_ANALYTICS", false) then
		return
	end

	local ANALYTICS_URL = "https://analytics.tez.capital/bake"

	local _analyticsCmd = string.interpolate(
		[[net.RestClient:new("${ANALYTICS_URL}", { timeout = 2 }):safe_post({ bakerId = "${bakerId}", version = "${version}" }); os.exit(0);]],
		{ bakerId = address, version = am.app.get_version(), ANALYTICS_URL = ANALYTICS_URL }
	)
	proc.spawn("eli", { "-e", _analyticsCmd }, { wait = false, stdio = "ignore" })
end

local function collect_service_info()
	local serviceManager = require "__xtz.service-manager"
	local _services = require "__xtz.services"

	for k, v in pairs(_services.allNames) do
		if type(v) ~= "string" then goto CONTINUE end
		local _ok, _status, _started = serviceManager.safe_get_service_status(v)
		ami_assert(_ok, "Failed to get status of " .. v .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)
		_info.services[k] = {
			status = _status,
			started = _started
		}
		if _status ~= "running" then
			set_status("error", "One or more signer services is not running!")
		end
		::CONTINUE::
	end
end

---@class PublicKey
---@field pkh string
---@field locator string

local function load_public_keys()
	---@type table<string, PublicKey>
	local public_keys = {}

	local ok, pubkey_hashs_file = fs.safe_read_file(path.combine(_homedir, ".tezos-signer/public_key_hashs"))
	if not ok then
		return false, "failed to read public_key_hashs file"
	end
	local ok, pubkey_hashs = hjson.safe_parse(pubkey_hashs_file)
	if not ok then
		return false, "failed to parse public_key_hashs file"
	end

	local pkhs = {}
	for _, wallet in ipairs(pubkey_hashs) do
		local name = wallet.name
		local pkh = wallet.value
		pkhs[name] = pkh
	end

	local ok, pubkeys_file = fs.safe_read_file(path.combine(_homedir, ".tezos-signer/public_keys"))
	if not ok then
		return false, "failed to read public_keys file"
	end
	local ok, pubkeys = hjson.safe_parse(pubkeys_file)
	if not ok then
		return false, "failed to parse public_keys file"
	end
	for _, wallet in ipairs(pubkeys) do
		local name = wallet.name
		public_keys[name] = {
			pkh = pkhs[name],
			locator = wallet.value and wallet.value.locator,
		}
	end

	return true, public_keys
end

local function collect_wallet_info()
	---@type table?
	local wallets_to_check = nil
	if type(_options.wallets) == "string" and _options.wallets ~= "true" then
		wallets_to_check = string.split(_options.wallets, ",")
	end

	local wallets = {}
	local ok, public_keys = load_public_keys()
	if not ok then
		set_status("error", public_keys)
		return
	end

	for wallet_id, wallet in pairs(public_keys --[[@as table<string, PublicKey>]]) do
		if type(wallet.locator) ~= "string" then
			goto CONTINUE
		end
		if wallets_to_check and not table.includes(wallets_to_check, wallet_id) then
			goto CONTINUE
		end

		local kind = "soft"
		local ledger = wallet.locator:match("ledger://([^/]+)/")
		if ledger then kind = "ledger" end
		-- "locator": "remote:<pkh>",
		local is_remote = wallet.locator:match("remote:([^,]+)") ~= nil
		if is_remote then kind = "remote" end

		wallets[wallet_id] = {
			pkh = wallet.pkh,
			kind = kind,
			ledger = ledger,
			ledger_status = ledger and "disconnected" or nil, -- we set disconnected as default and update it later, nil means not a ledger wallet
		}

		if wallet_id and wallet_id:match("baker") then
			send_analytics(wallet_id)
		end
		::CONTINUE::
	end

	local _args = { "list", "connected", "ledgers" }
	local _proc = proc.spawn("bin/signer", _args, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = _homedir }
	})

	local connected_ledgers = {}
	local output = _proc.exitcode == 0 and _proc.stdoutStream:read("a") or "failed"
	for ledger_id, backing_app_info, device, address in output:gmatch("## Ledger `(%S+-%S+-%S+)`%s+(.-)Ledger%s+(.-) at %[([%d%-%.]+:%d%.%d)%]") do
		local version = backing_app_info:match("Found%s+a%s+Tezos%s+Baking%s+(%d+%.%d+%.%d+)")
		if not version then
			set_status("error", "Baking app not found or not active on ledger: " .. ledger_id)
		end
		connected_ledgers[ledger_id] = {
			baking_app = version,
			device_address = address,
			device = device,
			ledger_status = "connected",
		}
	end

	for name, wallet in pairs(wallets) do
		if wallet.kind == "ledger" then
			local ledger = wallet.ledger
			local ledger_info = connected_ledgers[ledger]
			if not ledger_info then
				set_status("error", "Ledger device not found for wallet " .. name)
				goto CONTINUE
			end
			wallets[name] = util.merge_tables(wallet, ledger_info, true)
			-- check authorized
			if _skipLedgerAuthorizationCheck then
				goto CONTINUE
			end

			local _proc = proc.spawn("bin/signer", { "get", "ledger", "authorized", "path", "for", name }, {
				stdio = { stderr = "pipe" },
				wait = true,
				env = { HOME = _homedir }
			})

			local output = _proc.exitcode == 0 and _proc.stdoutStream:read("a") or "failed"
			local authorized = output:match("Authorized baking")
			wallets[name].authorized = authorized and true or false
			if not authorized then
				set_status("error", "Ledger device not authorized for wallet " .. name)
			end
		end
		::CONTINUE::
	end

	_info.wallets = wallets
end

if _printAll or _printServiceInfo then
	collect_service_info()
end

if _printAll or print_wallet_info then
	collect_wallet_info()
end

local SENSITIVE_FIELDS = { "ledger" }

local function hide_secrets(value)
	if is_sensitive_mode and type(value) == "table" then
		for k, v in pairs(value) do
			if type(v) == "string" and table.includes(SENSITIVE_FIELDS, k) then
				value[k] = v:gsub("(%a)(.*)(%a)", function(first, middle, last)
					return first .. middle:gsub("%a", "*") .. last
				end)
			elseif type(v) == "table" then
				value[k] = hide_secrets(v)
			end
		end
	end
	return value
end

if _json then
	print(hjson.stringify_to_json(hide_secrets(_info), { indent = false }))
else
	print(hjson.stringify(hide_secrets(_info), { sortKeys = true }))
end
