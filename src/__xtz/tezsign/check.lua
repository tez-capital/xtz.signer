local function get_devices()
	local process = proc.spawn("bin/tezsign", { "list-devices" }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = homedir }
	})

	ami_assert(process.exit_code == 0,
		"Failed to get connected devices: " .. (process.stderr_stream:read("a") or "unknown"))
	local output = process.stdout_stream:read("a") or ""
	-- json: [{"Serial":"444F57BB6DD642A29FC6B6B0F0222117","Manufacturer":"TzC","Product":"tezsign-gadget"}]
	local devices = hjson.parse(output)
	ami_assert(type(devices) == "table" and #devices > 0, "No connected devices found!", EXIT_APP_INTERNAL_ERROR)
	return devices
end

local function get_wallets()
    local tezsign_configuration = am.app.get_model("TEZSIGN_CONFIGURATION", nil)
    ami_assert(tezsign_configuration,
        "Tezsign configuration not found!", EXIT_APP_INTERNAL_ERROR)
    local device_id = tezsign_configuration.device_id
    
    local args = {"status"}
    if type(device_id) == "string" then
        table.insert(args, 1, device_id)
        table.insert(args, 1, "--device")
    end

    local process = proc.spawn("bin/tezsign", args, {
        stdio = { stderr = "pipe" },
        wait = true,
        env = { HOME = homedir }
    })
    ami_assert(process.exit_code == 0,
        "Failed to get wallets: " .. (process.stderr_stream:read("a") or "unknown"))

    -- [{"id":"baker","lock_state":"LOCKED","tz4":"tz4PLVFDLuEmzEP658FbXoDdggNRWe25ZgaZ","bl_pubkey":"BLpk1uxQVDyHRPkFeCTxLBzTZb6FRCUxQHBtUR2Pie8DtZpNWaotXaY1G2LiAbN4frM2tdq4KpDM","pop":"BLsigA5XZyuVvNBrVtwE6dCXhSFxVAEcZqWB7sqBgJTP2QENV6FNuApkyQ96PjJTDKiU9tqskfcZdqgGGkGX89ksKe6FAC11jLoALjoyddN6btukbbGt3PkVvvEf6qHBuNkB63nxZwEC59","last_block_level":0,"last_block_round":0,"last_preattestation_level":0,"last_preattestation_round":0,"last_attestation_level":0,"last_attestation_round":0,"state_corrupted":false}]
    local output = process.stdout_stream:read("a") or ""
    local wallets = hjson.parse(output)
    ami_assert(type(wallets) == "table",
        "Failed to parse wallets!", EXIT_APP_INTERNAL_ERROR)

    local result = {}
    for _, wallet in ipairs(wallets) do
        if type(wallet) == "table" and type(wallet.id) == "string" then
            result[wallet.id] = {
                kind = "tezsign",
                status = wallet.lock_state,
                authorized = wallet.lock_state == "UNLOCKED",
                pkh = wallet.tz4,
            }
        end
    end
    return result
end

return {
    get_devices = get_devices,
    get_wallets = get_wallets,
}