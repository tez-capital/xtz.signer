local hjson = require"hjson"
local io = require"io"

local specsContent = fs.read_file("./src/specs.json")
local specs = hjson.parse(specsContent)

print("ID=" .. specs.id)
print("VERSION=" .. specs.version)

local command = 'git tag -l "' .. specs.version .. '"'
local handle = io.popen(command)
local result = handle:read("*a")
handle:close()

if result ~= "" then
	print("NEEDS_RELEASE=true")
end