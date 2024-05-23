local options = ...

local setupLedgerPlatform = require("__xtz.ledger.platform")
local setupLedgerKey = require("__xtz.ledger.key")
local setupLedgerAuthorize = require("__xtz.ledger.authorize")

setupLedgerPlatform(options)
setupLedgerKey(options)
setupLedgerAuthorize(options)

-- reset permissions, because of platform setups we might run as root
require"__xtz.util".reset_datadir_permissions()