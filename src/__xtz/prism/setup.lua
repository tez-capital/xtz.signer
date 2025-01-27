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

local ok, err = prism_key_generator.generate_client("prism/keys/signer", "tezos-signer")
ami_assert(ok, err or "failed to generate signer key")

--- load and validate configuration
--- 
--- {
---     remote: <default_remote>,
---     listening_forwarders: {} # see prism docs
---     connecting_forwarders: {} # see prism docs
---     default_forwarder: {
---         signer: <true|false> # whether to provide access to signer for default_remote
---         node: <true|false> # whether default_remote provides access to the node
---         keys: path to prism key to use, defaults to "prism/keys/signer.prism"
---     }
--- }
local PRISM_CONFIGURATION = am.app.get_configuration("PRISM")
ami_assert(PRISM_CONFIGURATION, "PRISM configuration must be provided")

ami_assert(type(PRISM_CONFIGURATION.remote) == "string", "PRISM remote must be provided")

local are_listening_forwarders_valid_type = type(PRISM_CONFIGURATION.listening_forwarders) == "nil" or
    type(PRISM_CONFIGURATION.listening_forwarders) == "table"
ami_assert(are_listening_forwarders_valid_type, "invalid listening_forwarders type")
local are_connecting_forwarders_valid_type = type(PRISM_CONFIGURATION.connecting_forwarders) == "nil" or
    type(PRISM_CONFIGURATION.connecting_forwarders) == "table"
ami_assert(are_connecting_forwarders_valid_type, "invalid connecting_forwarders type")

-- generate configuration
local prism_configuration = {
    variables = {
        default_remote = PRISM_CONFIGURATION.remote,
        signer_endpoint = am.app.get_configuration("SIGNER_ENDPOINT", "127.0.0.1:20090"),
        local_rpc_endpoint = "127.0.0.1:" .. am.app.get_model("LOCAL_RPC_PORT", "8732")
    },
    listening_forwarders = PRISM_CONFIGURATION.listening_forwarders,
    connecting_forwarders = PRISM_CONFIGURATION.connecting_forwarders,
}

ami_assert(type(PRISM_CONFIGURATION.default_forwarder) == "nil" or PRISM_CONFIGURATION.default_forwarder == true or type(PRISM_CONFIGURATION.default_forwarder) == "table",
    "invalid 'PRISM.default_forwarder' type")
if type(table.get(prism_configuration.connecting_forwarders, "default_forwarder", nil)) ~= "nil" and type(PRISM_CONFIGURATION.default_forwarder) ~= "nil" then
    ami_error("PRISM.default_forwarder collides with PRISM.connecting_forwarders")
end

if PRISM_CONFIGURATION.default_forwarder == true then
    PRISM_CONFIGURATION.default_forwarder = {
        signer = true,
        rpc = true,
    }
end

if type(PRISM_CONFIGURATION.default_forwarder) == "table" then
    local connecting_forwarders = prism_configuration.connecting_forwarders or {}
    connecting_forwarders.default_forwarder = {
        connect_to = "${default_remote}",
        forward_to = PRISM_CONFIGURATION.default_forwarder.signer and "${signer_endpoint}" or nil,
        forward_from = PRISM_CONFIGURATION.default_forwarder.rpc and "${local_rpc_endpoint}" or nil,

        key_path =  PRISM_CONFIGURATION.default_forwarder.key or "prism/keys/signer.prism",
    }
    prism_configuration.connecting_forwarders = connecting_forwarders
end

local ok = fs.safe_write_file("prism/config.hjson", hjson.stringify(prism_configuration))
ami_assert(ok, "failed to write prism configuration")
