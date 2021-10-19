local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _blockNumber = am.app.get_configuration("BLOCK_NUMBER", "auto")

log_info("Getting latest block number...")
if _blockNumber == "auto" or _blockNumber == "AUTO" then
	local _bnSources = {
		"https://mainnet-tezos.giganode.io:443/",
		"https://mainnet.smartpy.io:443/",
		"https://teznode.letzbake.com:443/"
	}
	math.randomseed(os.time())
	local _bnSource = am.app.get_configuration("BLOCK_NUMBER_SOURCE", _bnSources[math.random(#_bnSources)])

	local _proc = proc.spawn("bin/client", { "-E", _bnSource, "rpc", "get", "/chains/main/blocks/head/header" }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = path.combine(os.cwd(), "data") }
	})

	ami_assert(_proc.exitcode == 0, "Failed to get block number: " .. _proc.stderrStream:read("a"))
	local _ok, _response = hjson.safe_parse(_proc.stdoutStream:read("a"))
	ami_assert(_ok, "Invalid response from block number source")
	_blockNumber = _response.level
end

am.app.set_model(_blockNumber, "BLOCK_NUMBER")
log_info("Got block number ".. _blockNumber ..".")
