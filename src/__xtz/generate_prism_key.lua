local options = ...

local prism_key_generator = require"__xtz.prism.key_generator"

local ok, err = prism_key_generator.generate(options.path, options["common-name"])
ami_assert(ok, err or "failed to generate key")

log_success("Generated " .. options.kind .. " key at " .. options.path)