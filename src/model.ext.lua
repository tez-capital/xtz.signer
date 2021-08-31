local _dataDir = path.combine(os.cwd(), "data")

am.app.set_model(
    {
		SIGNER_ADDR = am.app.get_configuration("SIGNER_ADDR", "0.0.0.0"),
		SIGNER_PORT = am.app.get_configuration("SIGNER_PORT", "2222"),
		BAKER_SSH_PORT = am.app.get_configuration("BAKER_SSH_PORT", "22")
    },
    { merge = true, overwrite = true }
)
