local user = am.app.get("user", "root")
ami_assert(type(user) == "string", "user not specified...", EXIT_INVALID_CONFIGURATION)
local tezsign_user = user .. "_tezsign" -- tezsign user related to the app user

local function create_tezsign_user()
    local system_os = am.app.get_model("SYSTEM_OS", "unknown")
    ami_assert(system_os == "unix", "only unix-like platforms are supported right now", EXIT_UNSUPPORTED_PLATFORM)

    local user_plugin, err = am.plugin.get("user")
    ami_assert(user_plugin, "failed to load user plugin - " .. tostring(err), EXIT_PLUGIN_LOAD_ERROR)

    local ok = user_plugin.add(tezsign_user, { disable_login = true, disable_password = true, fullname = user .. " tezsign operator" })
    ami_assert(ok, "failed to create user - " .. tezsign_user)

    local ok = user_plugin.add_group(tezsign_user)
    ami_assert(ok, "failed to create group - " .. tezsign_user)

    return tezsign_user
end

return {
    create = create_tezsign_user,
    username = tezsign_user
}