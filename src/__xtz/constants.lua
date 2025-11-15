local tezsign_configuration = require"__xtz.tezsign.configuration"

-- binaries
local wanted_binaries = { "signer", "client", "check-ledger" }

if am.app.get_configuration("PRISM") then
	table.insert(wanted_binaries, "prism")
end

if tezsign_configuration then
    table.insert(wanted_binaries, "tezsign")
end
-- end of binaries

return {
    protected_files = {
        "tezsign.config.hjson",
    },
    wanted_binaries = wanted_binaries,
}
