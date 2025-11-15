local tezsign_configuration_raw, _ = fs.read_file("./tezsign.config.hjson")
if not tezsign_configuration_raw then
    return false
end

local tezsign_configuration = hjson.parse(tezsign_configuration_raw)
if not tezsign_configuration then
    log_warn("failed to parse tezsign configuration")
    return false
end

-- normalize configuration

local listen = tezsign_configuration.listen
if listen == nil then
    listen = "127.0.0.1:20091"
end
if type(listen) ~= "string"  then
    log_warn("invalid tezsign configuration: listen must be a string")
    listen = "127.0.0.1:20091"
end

return util.merge_tables(tezsign_configuration, {
    listen = listen,
})