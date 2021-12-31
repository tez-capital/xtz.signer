local _appId = am.app.get("id")

return {
	[_appId .. "-xtz-signer"] = am.app.get_model("SIGNER_SERVICE_FILE", "__xtz/assets/signer.service")
}