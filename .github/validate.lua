local hjson = require("hjson")
-- validate version
local specs_raw = fs.read_file("src/specs.json")
local specs = hjson.parse(specs_raw)
local version, err = ver.parse(specs.version)
assert(version, "Failed to parse version: " .. (err or ""))
