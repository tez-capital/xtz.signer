local download_links = hjson.parse(fs.read_file("__xtz/sources.hjson"))
local download_urls = nil

local system_os = am.app.get_model("SYSTEM_OS", "unknown")
local system_distro = am.app.get_model("SYSTEM_DISTRO", "unknown")
local system_type = am.app.get_model("SYSTEM_TYPE", "unknown")

if system_os == "unix" then
    if system_distro == "MacOS" then
        download_urls = download_links["darwin-arm64"]
    else
        download_urls = download_links["linux-x86_64"]
        if system_type:match("[Aa]arch64") then
            download_urls = download_links["linux-arm64"]
        end
    end
end
ami_assert(download_urls ~= nil,
    "no download URLs found for the current platform: " .. system_os .. " " .. system_distro .. " " .. system_type)

am.app.set_model({
        DOWNLOAD_URLS = am.app.get_configuration("SOURCES", download_urls),
        REMOTE_SIGNER_PORT = am.app.get_configuration("REMOTE_SIGNER_PORT", "20090"),
        REMOTE_SSH_PORT = am.app.get_configuration("REMOTE_SSH_PORT", "22"),
        REMOTE_SSH_KEY = am.app.get_configuration("REMOTE_SSH_KEY"),
        REMOTE_NODE = am.app.get_configuration("REMOTE_NODE"),
        REMOTE_RPC_ENDPOINT = am.app.get_configuration("REMOTE_RPC_ENDPOINT", "127.0.0.1:8732"),
    },
    { merge = true, overwrite = true }
)

local endpoint = am.app.get_configuration("SIGNER_ENDPOINT", "127.0.0.1:20090")
local signer_addr = endpoint:match('([%d%.:]*):') or "127.0.0.1"
local signer_port = endpoint:match('[%d%.:]*:(%d*)') or "20090"

local TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info")

local constants = require("__xtz.constants").load()
local tezsign_configuration = require("__xtz.tezsign.configuration").load()
local tezsign_user = require "__xtz.tezsign.user".username

local tezsign_custom_file_permissions = {
    ["__bin_generated/tezsign.service.sh"] = "r-x------",
    ["tezsign.config.hjson"] = "r--------",
}
local tezign_custom_file_ownership = {
    ["__bin_generated/tezsign.service.sh"] = {
        user = tezsign_user,
        group = tezsign_user,
    },
    ["tezsign.config.hjson"] = {
        user = tezsign_user,
        group = tezsign_user,
    },
}
-- we set wanted binaries separately because on model reload the merge would combine old and new values
am.app.set_model(constants.wanted_binaries, "WANTED_BINARIES", { overwrite = true })

am.app.set_model(
    {
        SIGNER_ADDR = signer_addr,
        SIGNER_PORT = signer_port,
        SIGNER_ENDPOINT = endpoint,
        LOCAL_RPC_PORT = am.app.get_configuration("LOCAL_RPC_PORT", "8732"),
        SIGNER_LOG_LEVEL = TEZOS_LOG_LEVEL,
        -- prism
        PRISM_REMOTE = am.app.get_configuration({ "PRISM", "remote" }),
        PRISM_NODE_FORWARDING_DISABLED = am.app.get_configuration({ "PRISM", "node" }, false) ~= true,
        PRISM_SERVER_LISTEN_ON = am.app.get_configuration({ "PRISM", "listen" }),
        -- tezsign
        TEZSIGN_CONFIGURATION = tezsign_configuration,
        TEZSIGN_USER = tezsign_user,
        CUSTOM_FILE_PERMISSIONS = tezsign_configuration and tezsign_custom_file_permissions or {},
        CUSTOM_FILE_OWNERSHIP = tezsign_configuration and tezign_custom_file_ownership or {}
    },
    { merge = true, overwrite = true }
)
