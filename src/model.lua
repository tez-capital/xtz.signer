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
    end
end

if _downlaodUrls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model({
		DOWNLOAD_URLS = _downlaodUrls, 
		WANTED_BINARIES = {
			"client", "signer"
		}
	}, 
	{merge = true, overwrite = true}
)

local _dataDir = path.combine(os.cwd(), "data")

am.app.set_model(
    {
		SIGNER_ADDR = am.app.get_configuration("SIGNER_ADDR", "127.0.0.1"),
		SIGNER_PORT = am.app.get_configuration("SIGNER_PORT", "2222"),
		-- SIGNER_HTTP_ADDR = am.app.get_configuration("SIGNER_HTTP_ADDR", "127.0.0.1"),
		-- SIGNER_HTTP_PORT = am.app.get_configuration("SIGNER_HTTP_PORT", "2223"),
		BAKER_SSH_PORT = am.app.get_configuration("BAKER_SSH_PORT", "22")
    },
    { merge = true, overwrite = true }
)
