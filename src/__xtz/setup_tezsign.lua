local options = ...

local setup_tezsign_platform = require("__xtz.tezsign.platform")
local setup_tezsign_key = require("__xtz.tezsign.key")

setup_tezsign_platform(options)
setup_tezsign_key(options)

-- reset permissions, because of platform setups we might run as root
require"__xtz.base_utils".setup_file_ownership()