local function load_constants()
    local tezsign_configuration = require "__xtz.tezsign.configuration".load()

    -- binaries
    local wanted_binaries = {}

    if am.app.get_configuration("BACKEND", "octez") == "octez" then
        table.insert(wanted_binaries, "signer")
        table.insert(wanted_binaries, "client")
        table.insert(wanted_binaries, "check-ledger")
    end

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
end

return {
    load = load_constants,
}