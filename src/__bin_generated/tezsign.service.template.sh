#!/bin/sh

set -e

export TEZSIGN_UNLOCK_KEYS={{{model.TEZSIGN_CONFIGURATION.unlock_keys}}}
export TEZSIGN_UNLOCK_PASS={{{model.TEZSIGN_CONFIGURATION.unlock_password}}}

{{{ROOT_DIR}}}/bin/tezsign unlock
exec {{{ROOT_DIR}}}/bin/tezsign run --listen {{{model.TEZSIGN_CONFIGURATION.listen}}} --no-retry {{{configuration.STARTUP_TEZSIGN_ARGS__CLI_ARGS}}}