local options = ...

local active_exclisve_flags = 0
active_exclisve_flags = active_exclisve_flags + (options["generate"] and 1 or 0)
active_exclisve_flags = active_exclisve_flags + (options["import-key"] and 1 or 0)

ami_assert(active_exclisve_flags > 0, "At least one of the options 'generate' or 'import-key' must be specified!", EXIT_CLI_ARG_VALIDATION_ERROR)
ami_assert(active_exclisve_flags == 1, "Only one of the options 'generate' or 'import-key' can be specified!", EXIT_CLI_ARG_VALIDATION_ERROR)

local warning_message = [[

!!! WARNING !!!

!!! WARNING !!!

!!! WARNING !!!

Warning: Insecure Baking/Validating with Soft Wallet

Using a soft wallet for baking or validating Tezos blocks is not secure. This method was introduced solely for testing purposes. For production use, always employ a more secure signing method, such as hardware wallets or remote signers, to ensure the integrity and security of your operations.

To continue, type 'I understand the risks!' and press Enter.
]]

print(warning_message)

local response = io.read()
if response ~= "I understand the risks!" then
    log_error("You must type 'I understand the risks!' to continue.")
    os.exit(EXIT_APP_INTERNAL_ERROR)
end

local handlers = {
    ["generate"] = require("__xtz.soft.generate"),
    ["import-key"] = require("__xtz.soft.import")
}

for k, v in pairs(handlers) do
    if options[k] then
        v(options)
        break
    end
end