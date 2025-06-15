local hjson = require("hjson")
-- validate version
local specs_rwa = fs.read_file("src/specs.hjson")
local specs = hjson.parse(specs_rwa)
local version, err = ver.parse(specs.version)
assert(version, "Failed to parse version: " .. (err or ""))
