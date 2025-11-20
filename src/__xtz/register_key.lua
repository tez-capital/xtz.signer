local home_directory = path.combine(os.cwd(), "data")

local process = proc.spawn("bin/client", { "register", "key", "baker", "as", "delegate" }, {
	stdio = "inherit" ,
	wait = true,
	env = { HOME = home_directory },
	username = am.app.get("user"),
})
ami_assert(process.exit_code == 0, "Failed to register key as delegate!")
log_success("Keys successfully registered as delegate.")