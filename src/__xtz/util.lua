local util = {}

function util.reset_datadir_permissions()
	local user = am.app.get("user", "root")
	ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

	local ok, uid = fs.safe_getuid(user)
	ami_assert(ok, "Failed to get " .. user .. "uid - " .. (uid or ""))

	log_info("Granting access to " .. user .. "(" .. tostring(uid) .. ")...")
	local ok, error = fs.chown(os.cwd(), uid, uid, { recurse = true })
	ami_assert(ok, "Failed to chown data - " .. (error or ""))
end

-- Converts URLs to "host:port" format as described:
-- should be used only for RPC_ADDR and REMOTE_SIGNER_ADDR
-- "http://127.0.0.1/"        -> "127.0.0.1:80"
-- "https://127.0.0.1/"       -> "127.0.0.1:443"
-- "http://127.0.0.1:2090/"   -> "127.0.0.1:2090"
-- "127.0.0.1:90"             -> "127.0.0.1:90"
---@param input string
---@return string
function util.extract_host_and_port(input)
    -- Try to match URLs starting with "http://" or "https://"
    local protocol, host, port = string.match(input, "^(https?)://([^/:]+):?(%d*)")
    if protocol then
        -- Assign the default port when no port is provided
        if port == "" then
            if protocol == "http" then
                port = "80"
            elseif protocol == "https" then
                port = "443"
            end
        end
        return host .. ":" .. port
    else
        -- For strings without http(s)://, try matching a host:port pattern
        local host_only, port_only = string.match(input, "^([^/:]+):(%d+)")
        if host_only and port_only then
            return host_only .. ":" .. port_only
        else
            -- If the input doesn't match expected patterns, return it unchanged.
            return input
        end
    end
end

return util
