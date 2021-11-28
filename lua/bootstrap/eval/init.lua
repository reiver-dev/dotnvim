
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


function __complete_lua(arg, line, pos)
    return require"bootstrap.eval.lua_eval".complete(arg, pos)
end

return { setup = setup }
