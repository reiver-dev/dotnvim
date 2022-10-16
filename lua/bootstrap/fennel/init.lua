local M = {}

local function ensure_modules()
    local fennel = function()
        return require "fennel"
    end

    local fennelview = function()
        return require "fennel.view"
    end


    local aniseed = function(name)
        return "conjure." .. name
    end

    package.preload["fennelview"] = fennelview

    package.preload["aniseed.deps.fennel"] = fennel
    package.preload["aniseed.deps.fennelview"] = fennelview
    package.preload["aniseed.autoload"] = aniseed

    package.preload["conjure.aniseed.deps.fennel"] = fennel
    package.preload["conjure.aniseed.deps.fennelview"] = fennelview
end


local function complete_fennel(arg, line, pos)
    pos = pos - (#line - #arg)
    return require("bootstrap.fennel.repl").complete(arg, pos)
end


function M.setup()
    ensure_modules()
    require("bootstrap.fennel.loader").setup()

    vim.api.nvim_create_user_command(
        "EvalExpr",
        function(...) require("bootstrap.fennel.repl").eval_print(...) end,
        {
            desc = "bootstrap.fennel.repl::eval_print",
            complete = complete_fennel,
            nargs = '+',
        }
    )
end

return M
