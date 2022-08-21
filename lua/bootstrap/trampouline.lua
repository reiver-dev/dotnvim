--- Global trampouline function
--

local function tget(tbl, key)
    return tbl[key]
end


local function find(modname, funcname)
    local mod

    if modname ~= nil and modname ~= "" then
        mod = package.loaded[modname]
        if mod == nil then
            mod = require(modname)
        end
    else
        mod = _G
    end

    if funcname == nil or funcname == "" then
        if not vim.is_callable(mod) then
            error(("Module is not callable: %s"):format(modname))
        end
        return mod
    end

    local ok, func = pcall(tget, mod, funcname)
    if not ok then
        error(("Failed to index module %s:%s"):format(modname, funcname))
    end
    if func == nil then
        error(("Failed to find function %s:%s"):format(modname, funcname))
    end
    if not vim.is_callable(func) then
        error(("Function is not callable %s:%s"):format(modname, funcname))
    end

    return func
end


local function trampouline(modname, funcname, ...)
    return find(modname, funcname)(...)
end


local serialize

do
    local SERIALIZE_DISPATCH

    serialize = function(arg)
        return SERIALIZE_DISPATCH[type(arg)](arg)
    end

    local function serialize_table(arg)
        local chunks = {'{'}
        local i = 2
        for k, v in pairs(arg) do
            chunks[i] = string.format("[%s]=%s,", serialize(k), serialize(v))
            i = i + 1
        end
        chunks[i] = "}"
        return table.concat(chunks)
    end

    SERIALIZE_DISPATCH = {
        ["nil"] = tostring,
        ["bool"] = tostring,
        ["number"] = tostring,
        ["string"] = function(arg) return string.format("%q", arg) end,
        ["table"] = serialize_table,
        ["userdata"] = function() error("cannot serialize userdata") end,
        ["function"] = function() error("cannot serialize function") end,
    }
end


local function tf_no_upvalues(witharg, modname, funcname, ...)
    local argtext
    local n = select("#", ...)
    if n == 0 then
        argtext = ""
    elseif n == 1 then
        argtext = serialize((...)) .. ","
    else
        local args = {...}
        local res = {""}
        for i = 1,n do
            res[i+1] = serialize(args[i])
        end
        argtext = table.concat(res, ",") 
    end
    local vararg = witharg and ",..." or ""
    local text = string.format("return function()return _T(%q,%s%s%s)end",
                               modname, serialize(funcname), argtext, vararg)
    return assert(loadstring(text))()
end


local function args_append(dst, ...)
    local n1 = dst.n
    local n2 = select("#", ...)
    for i = 1,n2 do
        dst[i+n1] = select(i, ...)
    end
    return n1 + n2
end


local function tf_simple(modname, funcname, ...)
    local n = select("#", ...)
    if n == 0 then
        return function(...) return _T(modname, funcname, ...) end
    elseif n == 1 then
        local arg = ...
        return function(...) return _T(modname, funcname, arg, ...) end
    elseif n == 2 then
        local arg1, arg2 = ...
        return function(...) return _T(modname, funcname, arg1, arg2, ...) end
    else
        local args = {..., n = n}
        return function(...)
            local nargs = args_append(args, ...)
            return _T(modname, funcname, unpack(args, 1, nargs))
        end
    end
end


local function trampouline_func(modname, funcname, ...)
    vim.validate {
        modname = {modname, 'string'},
        funcname = {funcname, 'string', true}
    }
    return tf_simple(modname, funcname, ...)
end


local function trampouline_func_frozen(modname, funcname, ...)
    vim.validate {
        modname = {modname, 'string'},
        funcname = {funcname, 'string', true}
    }
    return tf_no_upvalues(false, modname, funcname, ...)
end


local function setup()
    _G._T = trampouline
    _G._F = trampouline_func
    _G._F0 = trampouline_func_frozen
end


return {
    setup = setup,
    trampouline = trampouline,
}

--- trampouline.lua ends here
