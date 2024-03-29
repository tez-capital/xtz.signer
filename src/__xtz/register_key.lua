local _user = am.app.get("user", "root")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _homedir = path.combine(os.cwd(), "data")

local _proc = proc.spawn("bin/client", { "register", "key", "baker", "as", "delegate" }, {
	stdio = "inherit" ,
	wait = true,
	env = { HOME = _homedir }
})
ami_assert(_proc.exitcode == 0, "Failed to register key as delegate!")
log_success("Keys successfully registered as delegate.")