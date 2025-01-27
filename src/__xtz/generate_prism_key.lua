local options = ...

local prism_key_generator = require"__xtz.prism.key_generator"

local generate_fn = nil
if options.kind == "client" then
    generate_fn = prism_key_generator.generate_client
elseif options.kind == "server" then
    generate_fn = prism_key_generator.generate_server
else
    ami_error("Invalid key kind: " .. options.kind)
    return
end

local ok, err = generate_fn(options.path, options["common-name"])
ami_assert(ok, err or "failed to generate key")

log_success("Generated " .. options.kind .. " key at " .. options.path)