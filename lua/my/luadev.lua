-- Setup lua-language-server for this config

local globals = {
    "_T", "_F", "_F0",
    "EVAL_AFTER_LOAD", "LOAD_PACKAGE", "RELOAD", "STDPATH",
    "SETLOCAL", "GETLOCAL",  "UPDLOCAL",
    "LOG", "SHELLSLASH", "SCAN_MODULES",
}


local function prepare()
    local settings = require("lua-dev").setup {
        library = {
            runtime = true,
            enabled = true,
            types = true,
            plugins = false,
        },
        lspconfig = {
            settings = {
                Lua = {
                    diagnostics = {
                        neededFileStatus = {
                            ["type-check"] = "Any"
                        },
                        disable = { "redefined-local" },
                        globals = globals,
                    }
                }
            }
        }
    }
    return settings
end


local function setup(opts)
    return require("lspconfig")["sumneko_lua"].setup(opts or prepare())
end


return {
    prepare = prepare,
    setup = setup,
}

-- luadev.lua ends here
