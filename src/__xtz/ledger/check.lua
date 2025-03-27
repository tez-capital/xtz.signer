local check_ledger = {}

local home_directory = path.combine(os.cwd() or ".", "data")

local function extract_checker_value(val)
    if type(val) ~= "string" then
        return nil, "unexpected value format"
    end
    -- format <value> or -,<error>
    if val:sub(1, 1) == "-" and #val > 2 then
        return nil, val:sub(3)
    end
    return val
end

local function get_ledger_id(ledger)
    if type(ledger) ~= "table" then
        return "invalid ledger device"
    end
    if type(ledger.id) == "string" and #ledger.id > 0 then
        return ledger.id
    end
    local bus = ledger.bus or ""
    local address = ledger.address or ""
    return "unknown-ledger-" .. bus .. "-" .. address
end

---@param bus string?
---@param address string?
---@param ledger_id string?
local function list_ledgers(bus, address, ledger_id)
    local args = {}

    if type(bus) == "string" and #bus > 0 then
        table.insert(args, "--bus")
        table.insert(args, bus)
    end
    if type(address) == "string" and #address > 0 then
        table.insert(args, "--address")
        table.insert(args, address)
    end
    if type(ledger_id) == "string" and #ledger_id > 0 then
        table.insert(args, "--ledger-id")
        table.insert(args, ledger_id)
    end

    local process = proc.spawn("bin/check-ledger", args, {
        stdio = { stderr = "pipe" },
        wait = true,
        env = { HOME = home_directory }
    })

    local output = process.exit_code == 0 and process.stdout_stream:read("a") or "failed"
    -- split by line
    local ledgers = {}
    for line in output:gmatch("[^\r\n]+") do
        -- format: <id>;<app version>;<curve>:<authorized path>;<bus>:<address>
        local errors = {}

        local p1, p2, p3, p4 = line:match("([^;]+);([^;]+);([^;]+);(.*)")
        local ledgerId, err = extract_checker_value(p1)
        if not ledgerId then
            table.insert(errors, err)
        end
        local appVersion, err = extract_checker_value(p2)
        if not appVersion then
            table.insert(errors, err)
        end
        local curve, authorized_path
        local authorized_path_info, err = extract_checker_value(p3)
        if not authorized_path_info then
            table.insert(errors, err)
        else
            curve, authorized_path = authorized_path_info:match("([^:]+):(.*)")
            if not curve then
                table.insert(errors, "unexpected value format")
            end
        end
        local busAddressInfo, err = extract_checker_value(p4)
        local bus, address
        if not busAddressInfo then
            table.insert(errors, err)
        else
            bus, address = busAddressInfo:match("([^:]+):(.*)")
            if not bus then
                table.insert(errors, "unexpected value format")
            end
        end

        table.insert(ledgers, {
            id = ledgerId,
            app_version = appVersion,
            curve = curve,
            authorized_path = tostring(curve) .. "/" .. tostring(authorized_path),
            bus = bus,
            address = address,
            errors = errors
        })
    end
    return ledgers
end

---@class LedgerInfo
---@field id string
---@field app_version string
---@field curve string
---@field authorized_path string
---@field bus string
---@field address string
---@field errors string[]

---List connected ledgers
---@param retries number? Number of retries
---@param ledgerId string? Ledger id to check_ledger
---@return table<string, LedgerInfo>
function check_ledger.list(retries, ledgerId)
    if type(retries) ~= "number" or retries < 1 then
        retries = 1
    end

    local ledgers = list_ledgers(nil, nil, ledgerId)

    local valid_ledgers = table.filter(ledgers, function(_, ledger)
        return type(ledger.id) == "string" and #ledger.id > 0
    end)

    local ledgers_not_loaded = table.filter(ledgers, function(_, ledger)
        return type(ledger.id) ~= "string" or #ledger.id == 0
    end)
    while retries > 0 and #ledgers_not_loaded > 0 do
        local new_ledgers_not_loaded = {}
        for _, ledger in ipairs(ledgers_not_loaded) do
            local reloaded_ledgers = list_ledgers(ledger.bus, ledger.address, 1)
            if #reloaded_ledgers > 0 then
                local ledgerInfo = reloaded_ledgers[1]
                if type(ledgerInfo.id) == "string" and #ledgerInfo.id > 0 then
                    table.insert(valid_ledgers, ledgerInfo)
                else
                    table.insert(new_ledgers_not_loaded, ledgerInfo)
                end
            else
                -- disconnected ledger ignore
            end
        end
        ledgers_not_loaded = new_ledgers_not_loaded
        retries = retries - 1
        os.sleep(200, "ms") -- wait 200ms
    end

    local result = {}
    for _, ledger in ipairs(valid_ledgers) do
        result[get_ledger_id(ledger)] = ledger
        log_debug("ledger device found: " .. get_ledger_id(ledger) .. " path: " .. tostring(ledger.authorized_path) .. " app version: " .. tostring(ledger.app_version))
    end
    for _, ledger in ipairs(ledgers_not_loaded) do
        result[get_ledger_id(ledger)] = ledger
    end

    return result
end

return check_ledger
