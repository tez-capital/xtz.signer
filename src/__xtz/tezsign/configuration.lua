local tezsign_configuration_raw, _ = fs.read_file("./tezsign.config.hjson")
if not tezsign_configuration_raw then
    return false
end

local tezsign_configuration = hjson.parse(tezsign_configuration_raw)
ami_assert(tezsign_configuration,
    "failed to parse tezsign configuration file './tezsign.config.hjson'")

-- normalize configuration
local default_endpoint = "127.0.0.1:20091"
if am.app.get_configuration("BACKEND", "octez") == "tezsign" then
    default_endpoint = am.app.get_configuration("SIGNER_ENDPOINT", "127.0.0.1:20090")
end

local listen = tezsign_configuration.listen
if listen == nil then
    listen = default_endpoint
end
if type(listen) ~= "string"  then
    log_warn("invalid tezsign configuration: listen must be a string")
    listen = default_endpoint
end

return util.merge_tables(tezsign_configuration, {
    listen = listen,
})