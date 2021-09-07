--- Fennel lisp user routines
--

require("bootstrap.fennel.compiler").initialize()

local fennel = require "fennel"
local compiler = require "fennel.compiler"
local view = require "fennel.view"

local M = {}

function M.environ(opts, env)
    local R = {}
    for k, v in pairs(package.loaded) do
        R[k:gsub("%.", "/")] = v
    end
    return setmetatable({ _A = opts, R = R }, {__index = env or _G})
end


function M.eval(opts, env)
    local env = M.environ(opts, env)
    local options = {
        env = env,
        filename = "EvalExpr.fnl",
        useMetadata = true
    }
    return fennel.eval(opts.rawargs, options)
end


local function collect_nested_keys(matches, input, tbl, prefix)
    local dedup = {}
    local len_input = #input
    local len_matches = #matches
    while tbl do
        if len_matches >= 1024 then
            return
        end

        for key, _ in pairs(tbl) do
            if (type(key) == "string"
                and input == key:sub(0, len_input)) then

                len_matches = len_matches + 1
                matches[len_matches] = prefix .. key
            end
            if len_matches >= 1024 then
                return
            end
        end
        
        local mt = getmetatable(tbl)
        if mt and type(mt.__index) == "table" then
            tbl = mt.__index
        else
            tbl = nil
        end
    end
end


local function find_completion_matches(matches, input, tbl, prefix)
    if #matches >= 1024 then
        return
    end
    local prefix = prefix and (prefix .. ".") or ""
    if not input:find("%.") then
        return collect_nested_keys(matches, input, tbl, prefix)
    end
    local head, tail = input:match("^([^.]+)%.(.*)")
    local nested = tbl[head]
    if type(nested) == "table" then
        return find_completion_matches(matches, tail, nested, prefix .. head)
    end
end


function M.prefix_map(input)
    local prefixes = {}
    local input_lens = {}

    do
        -- Multiple delimiters (empty part) is considered void
        -- and parts are merged back
        local parts = {}

        for part in vim.gsplit(input, "%s.") do
            if part == "" then
                local last = parts[#parts]
                if last then
                    last[#last + 1] = part
                else
                    parts[#parts] = {part}
                end
            else 
                local last = parts[#parts]
                if last and last[#last] == "" then
                    last[#last + 1] = part
                else
                    parts[#parts + 1] = {part}
                end
            end
        end

        for i = 1,#parts do
            local element = parts[i]
            if #element == 1 then
                parts[i] = element[1]
            else
                parts[i] = table.concat(element, ".")
            end
        end

        -- cumulative sum to make [begin_0, end_0, begin_1, end_1, ...]
        -- taking into account delimiter 
        do
            input_lens[1] = 1
            input_lens[2] = #(parts[1])
            local pos = 3
            local acc = input_lens[2]
            for i = 2,#parts do
                acc = acc + 1
                input_lens[pos] = acc + 1
                acc = acc + #(parts[i])
                input_lens[pos + 1]  = acc
                pos = pos + 2
            end
        end
    end


    local pref_pos = 1
    local len = #input_lens

    for i = 1,len,2 do
        local tail_pos = 1
        local tails = {}
        for j = i+1,len,2 do
            local start = input_lens[i]
            local stop = input_lens[j]
            tails[tail_pos] = input:sub(start, stop)
            tail_pos = tail_pos + 1
        end
        prefixes[pref_pos] = tails
        pref_pos = pref_pos + 1
    end

    return prefixes
end


function M.complete(text, pos)
    local suffix = pos and text:sub(pos) or ""
    local text = pos and text:sub(0, pos) or text
    local _, _, prefix, input = text:find("(.*[%s)(]+)(.*)")

    if not input then
        prefix = ""
        input = text
    end

    local scope = compiler.scopes.global
    local matches = {}
    local env = M.environ()

    find_completion_matches(matches, input, scope.specials or {})
    find_completion_matches(matches, input, scope.macros or {})
    find_completion_matches(matches, input, env)

    table.sort(matches)

    for i = 1,#matches do
        matches[i] = string.format("%s%s%s", prefix, matches[i], suffix)
    end

    return matches
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
    local t = fennel.traceback(message, 2):gsub("\n", "\n\t")
    return ("EvalExpr\n\t%s\n"):format(t):gsub("\t", "    ")
end


function M.eval_print(opts)
    accept(xpcall(function() return M.eval(opts); end, error_handler))
end


function M.repl(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.repl(options)
end

return M

--- repl.lua ends here
