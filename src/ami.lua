return {
    title = 'XTZ signer',
    commands = {
        info = {
            description = "ami 'info' sub command",
            summary = 'Prints runtime info and status of the app',
            action = '__xtz/info.lua',
            options = {
                ["services"] = {
                    description = "Prints info about services",
                    type = "boolean"
                },
                ["wallets"] = {
                    description = "Prints info about wallets",
                    type = "string"
                },
                ["skip-authorization-check"] = {
                    description = "Skips check baker authorization check on ledger",
                    type = "boolean"
                },
                ["sensitive"] = {
                    description = "Hide sensitive information",
                    type = "boolean"
                }
            },
            context_fail_exit_code = EXIT_APP_INFO_ERROR
        },
        setup = {
            options = {
                configure = {
                    description = 'Configures application, renders templates and installs services'
                }
            },
            action = function(options, _, _, _)
                local no_options = #table.keys(options) == 0
                if no_options or options.environment then
                    am.app.prepare()
                end

                if no_options or not options['no-validate'] then
                    am.execute('validate', { '--platform' })
                end

                if no_options or options.app then
                    am.execute_extension('__xtz/download-binaries.lua', { context_fail_exit_code = EXIT_SETUP_ERROR })
                end

                if no_options and not options['no-validate'] then
                    am.execute('validate', { '--configuration' })
                end

                if no_options or options.configure then
                    am.execute_extension('__xtz/create_user.lua', { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                    am.app.render()
                    am.execute_extension('__xtz/configure.lua', { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                end
                log_success('XTZ signer setup complete.')
            end
        },
        start = {
            description = "ami 'start' sub command",
            summary = 'Starts the XTZ signer',
            action = '__xtz/start.lua',
            context_fail_exit_code = EXIT_APP_START_ERROR
        },
        stop = {
            description = "ami 'stop' sub command",
            summary = 'Stops the XTZ signer',
            action = '__xtz/stop.lua',
            context_fail_exit_code = EXIT_APP_STOP_ERROR
        },
        validate = {
            description = "ami 'validate' sub command",
            summary = 'Validates app configuration and platform support',
            action = function(options, _, _, cli)
                if options.help then
                    am.print_help(cli)
                    return
                end
                -- //TODO: Validate platform
                ami_assert(proc.EPROC, 'xtz signer AMI requires extra api - eli.proc.extra', EXIT_MISSING_API)
                ami_assert(fs.EFS, 'xtz signer AMI requires extra api - eli.fs.extra', EXIT_MISSING_API)

                ami_assert(type(am.app.get('id')) == 'string', 'id not specified!', EXIT_INVALID_CONFIGURATION)
                ami_assert(
                    type(am.app.get_configuration()) == 'table',
                    'configuration not found in app.h/json!',
                    EXIT_INVALID_CONFIGURATION
                )
                ami_assert(type(am.app.get('user')) == 'string', 'USER not specified!', EXIT_INVALID_CONFIGURATION)
                ami_assert(
                    type(am.app.get_type()) == 'table' or type(am.app.get_type()) == 'string',
                    'Invalid app type!',
                    EXIT_INVALID_CONFIGURATION
                )
                log_success('XTZ signer configuration validated.')
            end
        },
        signer = {
            description = "ami 'signer' sub command",
            summary = 'Passes any passed arguments directly to tezos-signer.',
            index = 8,
            type = 'external',
            exec = 'bin/signer',
            environment = {
                HOME = path.combine(os.cwd(), "data")
            },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        client = {
            description = "ami 'signer' sub command",
            summary = 'Passes any passed arguments directly to tezos-client.',
            index = 9,
            type = 'external',
            exec = 'bin/client',
            environment = {
                HOME = path.combine(os.cwd(), "data")
            },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ['register-key'] = {
            description = "ami 'register-key' sub command",
            summary = 'Registers key as delegate.',
            index = 11,
            action = '__xtz/register_key.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ['setup-ledger'] = {
            description = "ami 'setup-ledger' sub command",
            summary = 'Setups ledger to bake for baker (or key based on alias).',
            options = {
                ["import-key"] = {
                    description =
                    "imports key for baking. To import custom derivation path use '--import-key=<derivation-path>'",
                    type = "auto"
                },
                ["ledger-id"] = {
                    description = 'imports key from specific ledger (used only if --import-key specified)',
                    type = "string"
                },
                ["authorize"] = {
                    description = "authorize baker on ledger",
                    type = "boolean"
                },
                ["chain-id"] = {
                    description = "specify custom chain id (used only if --authorize specified)",
                    type = "string"
                },
                ["hwm"] = {
                    description = "specify custom high watermark (used only if --authorize specified)",
                    type = "string"
                },
                ["key-alias"] = {
                    description =
                    "alias to use for the key we operate on (alias of imported key, key to use in hwm/chain setup etc.)",
                    type = "auto"
                },
                ["platform"] = {
                    description = "platform to setup ledger for",
                    type = "string"
                },
                ["no-udev"] = {
                    description = "skip udev rules setup (if --platform specified and platform is linux)",
                    type = "boolean"
                },
                ["protocol"] = {
                    description = "specify protocol (used only if --import-key or --authorize specified)",
                    type = "string"
                },
                force = {
                    description = 'forces operation, e.g. key import',
                    type = "boolean"
                }
            },
            index = 12,
            action = '__xtz/setup_ledger.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ['setup-soft-wallet'] = {
            description = "ami 'setup-soft-wallet' sub command",
            summary = 'Setups ledger to bake for baker (or key based on alias).',
            options = {
                ["import-key"] = {
                    description =
                    "imports key for baking. Usage: '--import-key=<key>'",
                    type = "auto"
                },
                ["generate"] = {
                    description = "Generate new key. Usage: '--generate=[signature-algo]'",
                    type = "string"
                },
                ["key-alias"] = {
                    description =
                    "alias to use for the key we operate on (alias of imported key, key to use in hwm/chain setup etc.)",
                    type = "auto"
                },
                force = {
                    description = 'forces operation, e.g. key import',
                    type = "boolean"
                }
            },
            index = 12,
            action = '__xtz/setup_soft_wallet.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ['get-key-hash'] = {
            description = "ami 'get-key-hash' sub command",
            summary = 'Returns hash if imported key.',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR,
            options = {
                alias = {
                    description = "key alias",
                    type = "string"
                }
            },
            action = function(_options, _, _, _)
                local ok, pkh_file = fs.safe_read_file("data/.tezos-client/public_key_hashs")
                assert(ok, "Failed to read 'public_key_hashes' file!")
                local ok, pkh = hjson.safe_parse(pkh_file)
                assert(ok, "Failed to parse 'public_key_hashes' file!")
                for _, v in ipairs(pkh) do
                    if v.name == (_options.alias or "baker") then
                        print(v.value)
                    end
                end
            end
        },
        log = {
            description = "ami 'log' sub command",
            summary = 'Prints logs from services.',
            options = {
                ["follow"] = {
                    aliases = { "f" },
                    description = "Keeps printing the log continuously.",
                    type = "boolean"
                },
                ["end"] = {
                    aliases = { "e" },
                    description = "Jumps to the end of the log.",
                    type = "boolean"
                },
                ["since"] = {
                    description = "Displays logs starting from the specified time or date. Format: 'YYYY-MM-DD HH:MM:SS'",
                    type = "string"
                },
                ["until"] = {
                    description = "Displays logs up until the specified time or date. Format: 'YYYY-MM-DD HH:MM:SS'",
                    type = "string"
                }
            },
            type = "namespace",
            action = '__xtz/log.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ['deposits-limit'] = {
            description = "ami 'deposit-limit' sub command",
            summary = 'Sets or unsets deposit limit.',
            options = {
                ["unset"] = {
                    description = "Unsets deposit limit.",
                    type = "boolean"
                },
                ["set"] = {
                    description = "Set deposit limit to specific amount of tez",
                    type = "number"
                }
            },
            action = '__xtz/deposits_limit.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        about = {
            description = "ami 'about' sub command",
            summary = 'Prints information about application',
            action = function(_options, _, _, _)
                local ok, about_raw = fs.safe_read_file('__xtz/about.hjson')
                ami_assert(ok, 'Failed to read about file!', EXIT_APP_ABOUT_ERROR)

                local ok, about = hjson.safe_parse(about_raw)
                about['App Type'] = am.app.get({ 'type', 'id' }, am.app.get('type'))
                ami_assert(ok, 'Failed to parse about file!', EXIT_APP_ABOUT_ERROR)
                if am.options.OUTPUT_FORMAT == 'json' then
                    print(hjson.stringify_to_json(about, { indent = false, skip_keys = true }))
                else
                    print(hjson.stringify(about))
                end
            end
        },
        remove = {
            index = 7,
            action = function(options, _, _, _)
                if options.all then
                    am.execute_extension('__xtz/remove-all.lua', { context_fail_exit_code = EXIT_RM_ERROR })
                    am.app.remove()
                    log_success('Application removed.')
                else
                    am.app.remove_data()
                    log_success('Application data removed.')
                end
                return
            end
        }
    }
}
