local function read_password(prompt)
    io.write(prompt)
    io.flush()

    -- Disable terminal echo
    os.execute("stty -echo")

    local status, password = pcall(io.read)

    -- Re-enable terminal echo
    os.execute("stty echo")
    io.write("\n")

    if not status then
        return nil, "Failed to read input"
    end

    return password
end

local function setup_password(option)
    if not option["password"] then
        log_debug("Skipping tezsign password prompt...")
        return
    end
    -- Usage
    local pwd, err = read_password("Enter TezSign Unlock Password: ")
    ami_assert(pwd, "Failed to read password: " .. tostring(err))
    log_info("TezSign password captured (len): " .. #pwd)

    local ok = fs.write_file("tezsign.secret", pwd, { atomic = true })
    ami_assert(ok, "Failed to write tezsign.secret file!")

    require "__xtz.base_utils".setup_file_permissions()
    return true
end

return setup_password