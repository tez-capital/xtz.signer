local needs_json_output = am.options.OUTPUT_FORMAT == "json"

local options = ...
local print_service_info = options.services
local print_wallet_info = options.wallets
local is_sensitive_mode = options["sensitive"]
local skip_ledger_check = options["skip-ledger-check"]
local print_all = (not print_wallet_info) and (not print_service_info)

local home_directory = path.combine(os.cwd() or ".", "data")

local info = {
	level = "ok",
	status = "Signer is operational",
	wallets = {},
	version = am.app.get_version(),
	type = am.app.get_type(),
	services = {}
}

local levels = { "ok", "warning", "error" }
local function index_of(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
	return -1
end

local function set_status(level, status)
	local level_index = index_of(levels, level)
	local info_index = index_of(levels, info.level)
	if level_index > info_index then
		info.level = level
		info.status = status
	end
end

local function send_analytics(address)
	if os.getenv("DISABLE_TEZBAKE_ANALYTICS") == "true" or am.app.get_configuration("DISABLE_ANALYTICS", false) then
		return
	end

	local ANALYTICS_URL = "https://analytics.tez.capital/bake"

	local analytics_cmd = string.interpolate(
		[[net.RestClient:new("${ANALYTICS_URL}", { timeout = 2 }):post({ bakerId = "${bakerId}", version = "${version}" }); os.exit(0);]],
		{ bakerId = address, version = am.app.get_version(), ANALYTICS_URL = ANALYTICS_URL }
	)
	proc.spawn("eli", { "-e", analytics_cmd }, { wait = false, stdio = "ignore" })
end

local function collect_service_info()
	local service_manager = require "__xtz.service-manager"
	local services = require "__xtz.services"

	local statuses, all_running = service_manager.get_services_status(services.active_names)
	info.services = statuses
	if not all_running then
		info.status = "one or more baker services is not running"
		info.level = "error"
	end
end

---@class PublicKey
---@field pkh string
---@field locator string

local function load_public_keys()
	---@type table<string, PublicKey>
	local public_keys = {}

	local pubkey_hashs_file, _ = fs.read_file(path.combine(home_directory, ".tezos-signer/public_key_hashs"))
	if not pubkey_hashs_file then
		return false, "failed to read public_key_hashs file"
	end
	local pubkey_hashs, _ = hjson.parse(pubkey_hashs_file)
	if not pubkey_hashs then
		return false, "failed to parse public_key_hashs file"
	end

	local pkhs = {}
	for _, wallet in ipairs(pubkey_hashs) do
		local name = wallet.name
		local pkh = wallet.value
		pkhs[name] = pkh
	end

	local pubkeys_file, _ = fs.read_file(path.combine(home_directory, ".tezos-signer/public_keys"))
	if not pubkeys_file then
		return false, "failed to read public_keys file"
	end
	local pubkeys, _ = hjson.parse(pubkeys_file)
	if not pubkeys then
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


local function are_ledger_paths_equal(path1, path2)
	-- split by / where first is curve and rest are parts

	local parts1 = string.split(path1, "/")
	local parts2 = string.split(path2, "/")

	-- compare curve
	if #parts1 < 2 or #parts2 < 2 or parts1[1] ~= parts2[1] then
		return false
	end

	-- we can not rely on equal path length, because octez configuration tends to
	-- shorten the path, skipping first 2 fields
	-- if #parts1 ~= #parts2 then
	-- 	return false
	-- end

	-- compare parts
	-- we compare from the end to the start and only up to the length of shortest path
	-- this may not be the best way to compare paths but it should work sufficiently
	local number_of_parts_to_compare = math.min(#parts1, #parts2) - 1 -- we skip curve
	for i = 0, number_of_parts_to_compare - 1 --[[ -1 because of subtraction ]] do
		local p1 = tostring(parts1[#parts1 - i]):match("(%d+)h?")
		local p2 = tostring(parts2[#parts2 - i]):match("(%d+)h?")
		if p1 ~= p2 then
			return false
		end
	end

	return true
end

local function collect_wallet_info()
	---@type table?
	local wallets_to_check = nil
	if type(options.wallets) == "string" and options.wallets ~= "true" then
		wallets_to_check = string.split(options.wallets, ",")
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
		local ledger, path = wallet.locator:match("ledger://([^/]+)/(.+)")
		if ledger then kind = "ledger" end
		-- "locator": "remote:<pkh>",
		local is_remote = wallet.locator:match("remote:([^,]+)") ~= nil
		if is_remote then kind = "remote" end

		wallets[wallet_id] = {
			pkh = wallet.pkh,
			kind = kind,
			ledger = ledger,
			ledger_status = ledger and "disconnected" or nil, -- we set disconnected as default and update it later, nil means not a ledger wallet
			path = path
		}

		send_analytics(wallet.pkh)
		::CONTINUE::
	end

	---@type table<string, LedgerInfo>
	local connected_ledgers = {}
	if not skip_ledger_check then
		local check_ledger = require "__xtz.ledger.check"
		if wallets_to_check then
			local ledger_ids = table.map(wallets_to_check, function(wallet_id)
				local wallet = wallets[wallet_id]
				if wallet and wallet.kind == "ledger" then
					return wallet.ledger
				end
			end)
			connected_ledgers = check_ledger.list(3, string.join_strings(",", table.unpack(ledger_ids)))
		else
			connected_ledgers = check_ledger.list(3)
		end
	end

	for name, wallet in pairs(wallets) do
		if wallet.kind == "ledger" then
			local ledger = wallet.ledger
			local ledger_info = connected_ledgers[ledger]
			if not ledger_info and not skip_ledger_check then
				set_status("error", "Ledger device not found for wallet " .. name)
				goto CONTINUE
			end
			if ledger_info then
				wallet.app_version = ledger_info.app_version
				wallet.ledger_status = "connected"
				wallet.device_bus = ledger_info.bus
				wallet.device_address = ledger_info.address
				wallet.authorized = are_ledger_paths_equal(wallet.path, ledger_info.authorized_path)
				if not wallet.authorized then
					set_status("error", "Ledger device not authorized for wallet " .. name)
				end
			else
				wallet.ledger_status = "disconnected"
				set_status("error", "Ledger device not found for wallet " .. name)
			end
		end
		::CONTINUE::
	end

	info.wallets = wallets
end

if print_all or print_service_info then
	collect_service_info()
end

if print_all or print_wallet_info then
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

if needs_json_output then
	print(hjson.stringify_to_json(hide_secrets(info), { indent = false }))
else
	print(hjson.stringify(hide_secrets(info), { sort_keys = true }))
end
