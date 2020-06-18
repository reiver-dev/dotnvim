--- Fennel lisp user routines
--

require"bootstrap.compiler".initialize()

local function eval(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return require"aniseed.fennel".eval(opts.rawargs, options)
end


local function eval_print(opts)
    print(require"aniseed.fennel".serialize(eval(opts)))
end


local function repl(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return require"aniseed.fennel".repl(options)
end

--- repl.lua ends here
