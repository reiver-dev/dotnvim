--- Better lua eval

local function complete_lua(arg, _, _)
    return require"bootstrap.eval.lua_eval".complete(arg)
end


local function setup()
    vim.api.nvim_add_user_command(
        "Eval",
        function(...) require "bootstrap.eval.lua_eval".eval(...) end,
        {
            desc = "bootstrap.eval.lua_eval::eval",
            complete = complete_lua,
            nargs = 1,
        }
    )
end


return { setup = setup, complete_lua = complete_lua }
