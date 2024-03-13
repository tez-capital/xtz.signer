local hjson = require"hjson"

local specsContent = fs.read_file("./src/specs.json")
local specs = hjson.parse(specsContent)

print("ID=" .. specs.id)
print("VERSION=" .. specs.version)
