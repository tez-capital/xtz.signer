local ok, platform_plugin = am.plugin.safe_get("platform")
if not ok then
    log_error("Cannot determine platform!")
    return
end
local ok, platform = platform_plugin.get_platform()
if not ok then
    log_error("Cannot determine platform!")
    return
end

local download_urls = nil

local download_links = hjson.parse(fs.read_file("__xtz/sources.hjson"))

if platform.OS == "unix" then
	download_urls = download_links["linux-x86_64"]
    if platform.SYSTEM_TYPE:match("[Aa]arch64") then
        download_urls = download_links["linux-arm64"]
    end
end

if download_urls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model({
		DOWNLOAD_URLS = am.app.get_configuration("SOURCES", download_urls),
        REMOTE_SIGNER_PORT = am.app.get_configuration("REMOTE_SIGNER_PORT", "20090"),
        REMOTE_SSH_PORT = am.app.get_configuration("REMOTE_SSH_PORT", "22"),
        REMOTE_SSH_KEY = am.app.get_configuration("REMOTE_SSH_KEY"),
        REMOTE_NODE = am.app.get_configuration("REMOTE_NODE"),
        REMOTE_RPC_ENDPOINT = am.app.get_configuration("REMOTE_RPC_ENDPOINT", "127.0.0.1:8732"),
        PLATFORM = platform
	},
	{merge = true, overwrite = true}
)

local services = require("__xtz.services")
local wanted_binaries = table.keys(services.signer_service_names)
table.insert(wanted_binaries, "client")
table.insert(wanted_binaries, "check-ledger")

if am.app.get_configuration("PRISM") then
    table.insert(wanted_binaries, "prism")
end

local endpoint = am.app.get_configuration("SIGNER_ENDPOINT", "127.0.0.1:20090")
local signer_addr = endpoint:match('([%d%.:]*):') or "127.0.0.1"
local signer_port = endpoint:match('[%d%.:]*:(%d*)') or "20090"

local TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info")

am.app.set_model(
    {
        WANTED_BINARIES = wanted_binaries,
        SIGNER_ADDR = signer_addr,
        SIGNER_PORT = signer_port,
        SIGNER_ENDPOINT = endpoint,
        LOCAL_RPC_PORT = am.app.get_configuration("LOCAL_RPC_PORT", "8732"),
        SIGNER_LOG_LEVEL = TEZOS_LOG_LEVEL,
        -- prism
        PRISM_REMOTE = am.app.get_configuration({ "PRISM", "remote" }),
        PRISM_NODE_FORWARDING_DISABLED = am.app.get_configuration({ "PRISM", "node" }, false) == true,
        PRISM_SERVER_LISTEN_ON = am.app.get_configuration({ "PRISM", "listen" }),
    },
    { merge = true, overwrite = true }
)
