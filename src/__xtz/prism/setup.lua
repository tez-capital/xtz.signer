--[[
# PATHS:
./prism
    - keys
        - ca.crt
        - ca.key
        - signer.prism
        - node.prism (optional)
        - dal.prism (optional)
    - conf.d
        - node.hjson
        - dal.hjson
    config.hjson
]]
log_info("setting up prism")
local prism_key_generator = require("__xtz/prism/key_generator")

fs.mkdirp("prism/keys")
-- fs.mkdirp("prism/conf.d") -- not needed for signer

local ok, err = prism_key_generator.generate("prism/keys/signer.prism", "signer.prism", "tezos-signer")
ami_assert(ok, err or "failed to generate signer key")

-- generate configuration
local REMOTE_PRISM = am.app.get_configuration("PRISM")
ami_assert(REMOTE_PRISM, "PRISM not set")

local prism_configuration = {
    connecting_forwarders = {
        default = {
            connect_to = REMOTE_PRISM,
            forward_to = am.app.get_model("SIGNER_PORT"),
            forward_from = am.app.get_model("LOCAL_RPC_PORT"),

            key_path = "prism/keys/signer.prism",
        }
    }
}

local ok = fs.safe_write_file("prism/config.hjson", hjson.stringify(prism_configuration))
ami_assert(ok, "failed to write prism configuration")