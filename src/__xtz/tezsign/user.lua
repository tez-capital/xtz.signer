local tezsign_user = am.app.get("user", "root")
ami_assert(type(tezsign_user) == "string", "user not specified...", EXIT_INVALID_CONFIGURATION)
tezsign_user = tezsign_user .. "_tezsign" -- tezsign user related to the app user

local function create_tezsign_user()
    local user = tezsign_user
    local system_os = am.app.get_model("SYSTEM_OS", "unknown")
    ami_assert(system_os == "unix", "only unix-like platforms are supported right now", EXIT_UNSUPPORTED_PLATFORM)

    local user_plugin, err = am.plugin.get("user")
    ami_assert(user_plugin, "failed to load user plugin - " .. tostring(err), EXIT_PLUGIN_LOAD_ERROR)

    local ok = user_plugin.add(user, { disable_login = true, disable_password = true, gecos = "" })
    ami_assert(ok, "failed to create user - " .. user)

    local ok = user_plugin.add_group(user)
    ami_assert(ok, "failed to create group - " .. user)

    return user
end

return {
    create = create_tezsign_user,
    username = tezsign_user
}