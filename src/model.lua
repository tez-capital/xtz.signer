local _ok, _platformPlugin = am.plugin.safe_get("platform")
if not _ok then
    log_error("Cannot determine platform!")
    return
end
local _ok, _platform = _platformPlugin.get_platform()
if not _ok then
    log_error("Cannot determine platform!")
    return
end

local _downlaodUrls = nil

local _downloadLinks = hjson.parse(fs.read_file("__xtz/sources.hjson"))

if _platform.OS == "unix" then
	_downlaodUrls = _downloadLinks["linux-x86_x64"]
    if _platform.SYSTEM_TYPE:match("[Aa]arch64") then
        _downlaodUrls = _downloadLinks["linux-arm64"]
    else
        local _ok, _cpuinfo = fs.safe_read_file("/proc/cpuinfo")
        if _ok and not _cpuinfo:match(" adx ") then
            _downlaodUrls = _downloadLinks["linux-x86_x64-no-adx"]
        end
    end
end

if _downlaodUrls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model({
		DOWNLOAD_URLS = _downlaodUrls
	},
	{merge = true, overwrite = true}
)

local _services = require("__xtz.services")
local _wantedBinaries = table.keys(_services.signerServiceNames)
table.insert(_wantedBinaries, "client")

local _endpoint = am.app.get_configuration("SIGNER_ENDPOINT", "127.0.0.1:2222")
local _signerAddr = _endpoint:match('([%d%.:]*):') or "127.0.0.1"
local _signerPort = _endpoint:match('[%d%.:]*:(%d*)') or "2222"

am.app.set_model(
    {
        WANTED_BINARIES = _wantedBinaries,
        REMOTE_SIGNER_PORT = am.app.get_configuration("REMOTE_SIGNER_PORT", "2222"),
        SIGNER_ADDR = _signerAddr,
        SIGNER_PORT = _signerPort,
        SIGNER_ENDPOINT = _endpoint,
        REMOTE_SSH_PORT = am.app.get_configuration("REMOTE_SSH_PORT", "22"),
        REMOTE_NODE = am.app.get_configuration("REMOTE_NODE"),
        REMOTE_RPC_ENDPOINT = am.app.get_configuration("REMOTE_RPC_ENDPOINT", "127.0.0.1:8732"),
        LOCAL_RPC_PORT = am.app.get_configuration("LOCAL_RPC_PORT", "8732"),
        REMOTE_SSH_KEY = am.app.get_configuration("REMOTE_SSH_KEY")
    },
    { merge = true, overwrite = true }
)
