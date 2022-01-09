--- Enchanced lua command



local require_missing_mt = {
    __index = function(t, key)
        local val = require(key:gsub("__", "."))
        rawset(t, key, val)
        return val
    end,
    __newindex = function()
        error("Require trampouline is immutable")
    end,
}


local function exec_environ(opts, env)
    local R = setmetatable({}, require_missing_mt)
    return setmetatable({ _A = opts, R = R }, {__index = env or _G})
end


local function repl_environ(opts, env)
    local R = {}
    for k, v in pairs(package.loaded) do
        R[k:gsub("%.", "__")] = v
    end
    return setmetatable({ _A = opts, R = R }, {__index = env or _G})
end

local template_stmt = [[local function Eval()
%s
end
return Eval()
]]


local template_expr = [[local function Eval(...) return ... end
return Eval(%s)
]]


local keywords = {
    ["do"] = true,
    ["end"] = true,
    ["if"] = true,
    ["elseif"] = true,
    ["else"] = true,
    ["function"] = true,
    ["local"] = true,
    ["for"] = true,
    ["while"] = true,
    ["repeat"] = true,
    ["return"] = true,
}

local function is_statement(text)
    local start, stop = string.find(text, "%s*%w+%s*")
    if start == nil then
        return false
    end
    local first_word = vim.trim(text:sub(start, stop))
    return keywords[first_word] ~= nil
end


local function eval(opts, env)
    local text = opts.rawargs or opts.args
    local env = exec_environ(opts, env)
    local template
    local kind
    if is_statement(text) then
        template = template_stmt
        kind = "=EvalStatement"
    else
        template = template_expr
        kind = "=EvalExpression"
    end
    local program = template:format(text)
    local f, err = loadstring(program, kind)
    if f == nil then
        error(err)
    end
    setfenv(f, env)
    return f()
end


local view = vim.inspect


local function error_handler(message)
    if type(message) == "table" then
        local mt = getmetatable(message)
        if mt ~= nil and mt.__tostring ~= nil then
            message = string.format("Error String: %q\n       Value: %s",
                                    tostring(message), view(message))
        else
            message = string.format("Error Value: %s", view(message))
        end
    elseif type(message) ~= "string" then
        message = string.format("Error Value: %s", view(message))
    end
    local t = debug.traceback(message, 2):gsub("\n", "\n\t")
    return ("EvalExpr\n\t%s\n"):format(t):gsub("\t", "    ")
end


local function complete(text)
    local completions, plen = vim._expand_pat("^" .. text, repl_environ())
    local prefix = text:sub(1, plen)
    for i = 1,#completions do
        completions[i] = prefix .. completions[i]
    end
    return completions
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


local function eval_print(opts)
    accept(xpcall(function() return eval(opts); end,
                  error_handler))
end


return {
    complete = complete,
    eval = eval_print
}

--- lua_eval.lua ends here
