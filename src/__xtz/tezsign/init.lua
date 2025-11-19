local empty_configuration = [[
{
    // NO need to set anything here if you use just one tezsign device
    // the ami/tezbake will pick the first connected device automatically
    // device_id: <serial number>

    // if you want to unlock keys automatically on startup
    // you can set the keys and password here
    // if left empty and password is set all keys will be unlocked
    // unlock_keys: alias1,alias2

    // and the password to unlock them here
    // unlock_password: your_password_here

    // usually you do not want to do this
    // if not set the ami/tezbake handles it for you automatically
    // but if you need to run multiple tezbake instances on the same machine
    // you may have to override the port to avoid conflicts
    // listen: 127.0.0.1:20090
}]]

local function init(options)
    if not options["init"] then
        log_debug("Skipping tezsign initialization...")
        return
    end

    log_info("Initializing tezsign configuration...")
    local tezsign_configuration_raw, _ = fs.read_file("./tezsign.config.hjson")
    if not tezsign_configuration_raw then
        local ok = fs.write_file("./tezsign.config.hjson", empty_configuration)
        ami_assert(ok, "Failed to create tezsign configuration file!")
        log_success("Created default tezsign configuration file at './tezsign.config.hjson'")
    else
        log_info("tezsign configuration already exists.")
    end

    am.app.load_model() -- reload models to get updated configuration
    am.execute("setup", { "--app", "--configure", "--no-validate" })
end

return init
