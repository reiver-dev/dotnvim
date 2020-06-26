--- Fennel lisp user routines
--

require"bootstrap.fennel.compiler".initialize()
local fennel = require "aniseed.deps.fennel"
local view = require "aniseed.deps.fennelview"

local M = {}

function M.eval(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.eval(opts.rawargs, options)
end


function M.eval_print(opts)
    print(view(M.eval(opts)))
end


function M.repl(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.repl(options)
end

return M

--- repl.lua ends here
