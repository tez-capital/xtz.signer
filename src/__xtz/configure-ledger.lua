-- Setup ledger
local _tmpFile = os.tmpname()
local _udevRulesUrl = "https://raw.githubusercontent.com/alis-is/udev-rules/f15dc1eb83a4f3c666f58c12a93c45c6fca3a004/add_udev_rules.sh"
local _ok, _error = net.safe_download_file(_udevRulesUrl, _tmpFile, {followRedirects = true})
if not _ok then
	fs.remove(_tmpFile)
	ami_error("Failed to download: " .. tostring(_error))
end
local _proc = proc.spawn("/bin/bash", { _tmpFile }, {
	stdio = { stderr = "pipe" },
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})

fs.remove(_tmpFile)
ami_assert(_proc.exitcode == 0, "Failed to setup udev rules : " .. _proc.stderrStream:read("a"))
-- ami_assert(os.execute("udevadm trigger"), "Failed to run 'udevadm trigger'!")
-- ami_assert(os.execute("udevadm control --reload-rules"), "Failed to run 'udevadm control --reload-rules'!")