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
    local path = ledger.path or ""
    return "unknown-ledger-" .. path
end

---@param path string?
---@param ledger_id string?
local function list_ledgers(path, ledger_id)
    local args = {}

    if type(path) == "string" and #path > 0 then
        table.insert(args, "--path")
        table.insert(args, path)
    end
    if type(ledger_id) == "string" and #ledger_id > 0 then
        table.insert(args, "--ledger-id")
        table.insert(args, ledger_id)
    end

    local process, err = proc.spawn("bin/check-ledger", args, {
        stdio = { stderr = "pipe" },
        wait = true,
        env = { HOME = home_directory },
        username = am.app.get("user"),
    })

    if not process then
        log_error("Failed to spawn check-ledger process: " .. tostring(err))
        return {}
    end

    local output = process.exit_code == 0 and process.stdout_stream:read("a") or "failed"
    -- split by line
    local ledgers = {}
    for line in output:gmatch("[^\r\n]+") do
        -- format: <id>;<app version>;<curve>:<authorized path>;<path>
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
        local path, err = extract_checker_value(p4)
        if not path then
            table.insert(errors, err)
        end

        table.insert(ledgers, {
            id = ledgerId,
            app_version = appVersion,
            curve = curve,
            authorized_path = tostring(curve) .. "/" .. tostring(authorized_path),
            path = path,
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
---@field path string
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
            local reloaded_ledgers = list_ledgers(ledger.path, 1)
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
