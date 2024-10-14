-- gen keys <new> [-f --force] [-s --sig <ed25519|secp256k1|p256|bls>]

-- show address baker

local function setup(options)
    log_info("Generating soft-wallet keys...")

    local homedir = path.combine(os.cwd(), "data")

    local serviceManager = require "__xtz.service-manager"
    local services = require "__xtz.services"
    local ok, status, _ = serviceManager.safe_get_service_status(services.signerServiceId)
    ami_assert(ok and status ~= "running",
        services.signerServiceId .. " is already running. Please stop it to generate keys...",
        EXIT_APP_INTERNAL_ERROR)

    local alias = "baker"
    if options["key-alias"] then
        alias = options["key-alias"]
        ami_assert(type(alias) == "string", "Invalid alias detected!", EXIT_CLI_ARG_VALIDATION_ERROR)
    end

    local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
    if type(options.protocol) == "string" then
        protocol = options.protocol
    end

    local _proc = proc.spawn("bin/signer",
        { "gen", "keys", alias or "baker",
            "-s", options.sig or "ed25519",
            options.force and "--force" or nil }, {
            stdio = "inherit",
            wait = true,
            env = { HOME = homedir }
        })
    ami_assert(_proc.exitcode == 0, "Failed to generate keys!")

    -- get private key
    -- show address <alias> -S
    local _proc = proc.spawn("bin/signer",
        { "show", "address", alias, "-S" }, {
            stdio = { output = "pipe" },
            wait = true,
            env = { HOME = homedir }
        })

    -- Hash: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    -- Public Key:  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    -- Secret Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    local output = _proc.stdoutStream:read("a") or ""
    local secret_key = output:match("Secret Key: (.+)")

    -- import into client
    local _proc = proc.spawn("bin/client",
        { "-p", protocol, "import", "secret", "key", alias or "baker", secret_key,
            options.force and "--force" or nil }, {
            stdio = "inherit",
            wait = true,
            env = { HOME = homedir }
        })
    ami_assert(_proc.exitcode == 0, "Failed to import key to client!")

    log_success("Soft-wallet keys successfully generated.")
end

return setup