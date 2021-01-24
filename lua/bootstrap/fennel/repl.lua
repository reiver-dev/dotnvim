--- Fennel lisp user routines
--

require"bootstrap.fennel.compiler".initialize()
local fennel = require "aniseed.deps.fennel"
local view = require "aniseed.deps.fennelview"

local M = {}

function M.eval(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G}),
        filename = "EvalExpr.fnl",
        useMetadata = true
    }
    return fennel.eval(opts.rawargs, options)
end


local function recur_view(a, ...)
    if select("#", ...) == 0 then
        return view(a), ""
    else
        return view(a), recur_view(...)
    end
end


local function accept(status, ...)
    if status then
        vim.api.nvim_out_write(table.concat({recur_view(...)}, "\n"))
    else
        vim.api.nvim_err_write(...)
    end
end


local function error_handler(message)
    return ("%s\nCaused by:\n\t%s\n"):format(
        debug.traceback("ERROR EvalExpr", 2),
        message:gsub("\n", "\n\t")
    ):gsub("\t", "    ")
end


function M.eval_print(opts)
    accept(xpcall(M.eval, error_handler, opts))
end


function M.repl(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.repl(options)
end

return M

--- repl.lua ends here
