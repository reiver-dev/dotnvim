--- Better lua eval

local function complete_lua(arg, line, pos)
    local offset = pos - (#line - #arg)
    local prefix = string.sub(arg, 1, offset)
    return require"bootstrap.eval.lua_eval".complete(prefix)
end


local function setup()
    vim.api.nvim_create_user_command(
        "Eval",
        function(...) require "bootstrap.eval.lua_eval".eval(...) end,
        {
            desc = "bootstrap.eval.lua_eval::eval",
            complete = complete_lua,
            nargs = '+',
        }
    )
end


return { setup = setup, complete_lua = complete_lua }
