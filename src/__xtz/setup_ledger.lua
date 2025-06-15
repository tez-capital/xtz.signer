local options = ...

local setup_ledger_platform = require("__xtz.ledger.platform")
local setup_ledger_key = require("__xtz.ledger.key")
local setup_ledger_authorize = require("__xtz.ledger.authorize")

setup_ledger_platform(options)
setup_ledger_key(options)
setup_ledger_authorize(options)

-- reset permissions, because of platform setups we might run as root
require"__xtz.base_utils".setup_file_ownership()