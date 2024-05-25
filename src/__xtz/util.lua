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

return util
