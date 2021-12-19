
local function setup()
    local interop = require "bootstrap.interop"
    local def = interop.command{
        name = "Eval",
        nargs = 1,
        -- complete = "lua",
        complete = "customlist,v:lua.__complete_lua",
        modname = "bootstrap.eval.lua_eval",
        funcname = "eval"
    }
    vim.cmd(def)
end


local function complete_lua(arg, _, _)
    return require"bootstrap.eval.lua_eval".complete(arg)
end

_G.__complete_lua = complete_lua

return { setup = setup, complete_lua = complete_lua }
