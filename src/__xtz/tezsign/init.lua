local function init(options)
    if not options["init"] then
        log_debug("Skipping tezsign initialization...")
        return
    end

    log_info("Initializing tezsign configuration...")
    local tezsign_configuration_raw, _ = fs.read_file("./tezsign.config.hjson")
    if not tezsign_configuration_raw then
        local ok = fs.write_file("./tezsign.config.hjson", "{\n\n}")
        ami_assert(ok, "Failed to create tezsign configuration file!")
        log_success("Created default tezsign configuration file at './tezsign.config.hjson'")
    else
        log_info("tezsign configuration already exists.")
    end

    am.execute_action("setup") -- trigger app setup
end

return init
