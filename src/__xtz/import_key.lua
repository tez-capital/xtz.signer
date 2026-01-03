local args = table.pack(...)

ami_assert(#args > 0, "Please provide baker address...")

local homedir = path.combine(os.cwd(), "data")

local alias = "baker"
local force = false
local protocol = "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
for _, v in ipairs(args) do
	if string.trim(v) == "-f" or string.trim(v) == "--force" then
		force = true
	end
	if string.trim(v):sub(1, 3) == "-a=" then
		alias = string.trim(v):sub(4)
	elseif string.trim(v):sub(1, 8) == "--alias=" then
		alias = string.trim(v):sub(9)
	end
    if string.trim(v):sub(1, 3) == "-p=" then
        protocol = string.trim(v):sub(4)
    elseif string.trim(v):sub(1, 8) == "--protocol=" then
        protocol = string.trim(v):sub(12)
    end
end

local process = proc.spawn("bin/signer",
		{ "import", "secret", "key", alias or "baker", args[1],
			force and "--force" or nil }, {
			stdio = "inherit",
			wait = true,
			env = { HOME = homedir },
			username = am.app.get("user"),
		})
ami_assert(process.exit_code == 0, "Failed to import key to signer!")

local process = proc.spawn("bin/client",
    { "-p", protocol, "import", "secret", "key", alias or "baker", args[1],
        force and "--force" or nil }, {
        stdio = "inherit",
        wait = true,
        env = { HOME = homedir },
        username = am.app.get("user"),
    })
ami_assert(process.exit_code == 0, "Failed to import key to client!")