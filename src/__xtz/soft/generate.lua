-- gen keys <new> [-f --force] [-s --sig <ed25519|secp256k1|p256|bls>]

-- show address baker

local function setup(options)
    log_info("Generating soft-wallet keys...")

    local homedir = path.combine(os.cwd(), "data")

    local service_manager = require "__xtz.service-manager"
    local services = require "__xtz.services"
    ami_assert(not service_manager.have_all_services_status({ services.signer_service_id }, "running"),
        services.signer_service_id .. " is already running. Please stop it to generate keys...",
        EXIT_APP_INTERNAL_ERROR)

    local alias = "baker"
    if options["key-alias"] then
        alias = options["key-alias"]
        ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
    end

    local signature = "ed25519"
    if type(options["generate"]) == "string" and options["generate"] ~= "" and options["generate"] ~= "true" then
        signature = options["generate"]
    end

    local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
    if type(options.protocol) == "string" then
        protocol = options.protocol
    end

    local process = proc.spawn("bin/signer",
        { "gen", "keys", alias or "baker",
            "-s", signature,
            options.force and "--force" or nil }, {
            stdio = "inherit",
            wait = true,
            env = { HOME = homedir },
            username = am.app.get("user"),
        })
    ami_assert(process.exit_code == 0, "Failed to generate keys!")

    -- get private key
    -- show address <alias> -S
    local process = proc.spawn("bin/signer",
        { "show", "address", alias, "-S" }, {
            stdio = { output = "pipe" },
            wait = true,
            env = { HOME = homedir },
            username = am.app.get("user"),
        })

    -- Hash: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    -- Public Key:  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    -- Secret Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    local output = process.stdout_stream:read("a") or ""
    local secret_key = output:match("Secret Key: (.+)")

    -- import into client
    local process = proc.spawn("bin/client",
        { "-p", protocol, "import", "secret", "key", alias or "baker", secret_key,
            options.force and "--force" or nil }, {
            stdio = "inherit",
            wait = true,
            env = { HOME = homedir },
            username = am.app.get("user"),
        })
    ami_assert(process.exit_code == 0, "Failed to import key to client!")

    log_success("Soft-wallet keys successfully generated.")
end

return setup
