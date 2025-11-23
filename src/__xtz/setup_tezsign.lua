local options = ...

local init = options.init
local import_key = options["import-key"]

if init and import_key then
    ami_error("The '--init' option cannot be used together with '--import-key' option.",
        EXIT_CLI_ARG_VALIDATION_ERROR)
end

local init = require("__xtz.tezsign.init")
init(options)

local setup_tezsign_platform = require("__xtz.tezsign.platform")
setup_tezsign_platform(options)

local setup_tezsign_password = require("__xtz.tezsign.password")
setup_tezsign_password(options)

local setup_tezsign_key = require("__xtz.tezsign.key")
setup_tezsign_key(options)

-- reset permissions, because of platform setups we might run as root
require"__xtz.base_utils".setup_file_ownership()