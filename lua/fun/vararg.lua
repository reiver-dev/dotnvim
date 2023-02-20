--- Vararg traversal

local MODULE = ...

local string_format = string.format
local string_rep = string.rep
local table_concat = table.concat
local loadstring = loadstring
local tostring = tostring
local error = error
local select = select
local setmetatable = setmetatable
--- @diagnostic disable-next-line: deprecated
local unpack = _G.unpack or table.unpack

local band = bit.band
local bor = bit.bor
local brshift = bit.rshift
local blshift = bit.lshift


--- @generic V
--- @param ... V
--- @return V[]
local function pack(...)
    return {n = select("#", ...), ...}
end

--- Load lua code with name as debug info
--- @param template string
--- @param name string
--- @return function
local function compile_template(template, name)
    local res, err = loadstring(template, name)
    if res then
        return res()
    else
        error(err)
    end
end


local function _tget(i)
    return "tbl[" .. tostring(i) .. "]"
end


local function argtable(fmt, n)
    local tbl = {}
    for i in 1,n do
        tbl[i] = fmt(i)
    end
    return tbl
end


--- Format lua custom chunkname
--- @param name string
--- @param n integer
--- @return string
local function _chunkname(name, n)
    return string_format("=%s.%s(%d)", MODULE, name, n)
end


--- Format lua custom chunkname
--- @param name string
--- @param a integer
--- @param b integer
--- @return string
local function _chunkname2(name, a, b)
    return string_format("=%s.%s(%d,%d)", MODULE, name, a, b)
end


local function fallback_unpack(n, tbl)
    return unpack(tbl, 1, n)
end


local function prepare_fallback_unpack(n)
    return function(tbl) fallback_unpack(n, tbl) end
end


--- @param tbl  table
--- @param start integer
--- @param stop integer
--- @param dst integer
--- @param ntbl table
--- @return table a2
local function table_move(tbl, start, stop, dst, ntbl)
    for i = start,stop,1 do
        ntbl[dst] = tbl[i]
        dst = dst + 1
    end
    return ntbl
end


local function fallback_unpack_add(n, tbl, tail)
    local ntbl = table_move(tbl, 1, n, 1, {})
    ntbl[n + 1] = tail
    ntbl.n = n + 1
    return unpack(ntbl, 1, n + 1)
end



local function prepare_fallback_unpack_add(n)
    return function(tbl, tail) fallback_unpack_add(n, tbl, tail) end
end



local function fallback_unpack_tail(n, tbl, ...)
    local tail_len = select("#", ...)
    if tail_len == 0 then
        return unpack(tbl, 1, n)
    elseif tail_len == 1 then
        return fallback_unpack_add(n, tbl, ...)
    else
        local ntbl = {...}
        table_move(ntbl, 1, tail_len, n + tail_len, ntbl)
        table_move(tbl, 1, n, 1, ntbl)
        return unpack(ntbl, 1, n + tail_len)
    end
end


local function prepare_fallback_unpack_tail(n)
    return function(tbl, ...) fallback_unpack_tail(n, tbl, ...) end
end


local unpack_cache = setmetatable({
    function(tbl) return tbl[1] end,
    function(tbl) return tbl[1], tbl[2] end,
    function(tbl) return tbl[1], tbl[2], tbl[3] end,
}, {
    __index = function(t, n)
        if n >= 248 then return prepare_fallback_unpack(n) end
        local template = [[return function(tbl) return %s end]]
        local arglist = table_concat(argtable(_tget, n), ",")
        local f = compile_template(string_format(template, arglist, arglist), _chunkname("unpack", n))
        rawset(t, n, f)
        return f
    end
})


--- @param tbl table
--- @return ...
local function this_unpack(tbl)
    local count = tbl.n or #tbl
    if count == 0 then return end
    return unpack_cache[count](tbl)
end


local unpack_add_cache = setmetatable({
    function(tbl, tail) return tbl[1], tail end,
    function(tbl, tail) return tbl[1], tbl[2], tail end,
    function(tbl, tail) return tbl[1], tbl[2], tbl[3], tail end,
}, {
    __index = function(t, n)
        if n >= 247 then return prepare_fallback_unpack_add(n) end
        local template = [[return function(tbl,tail) return %s,tail end]]
        local arglist = table_concat(argtable(_tget, n), ",")
        local f = compile_template(string_format(template, arglist, arglist), _chunkname("unpack_add", n))
        rawset(t, n, f)
        return f
    end
})


local unpack_tail_cache = setmetatable({
    function(tbl, ...) return tbl[1], ... end,
    function(tbl, ...) return tbl[1], tbl[2], ... end,
    function(tbl, ...) return tbl[1], tbl[2], tbl[3], ... end,
}, {
    __index = function(t, n)
        if n >= 247 then return prepare_fallback_unpack_tail(n) end
        local template = [[return function(tbl,...) return %s,... end]]
        local arglist = table_concat(argtable(_tget, n), ",")
        local f = compile_template(string_format(template, arglist, arglist), _chunkname("unpack_tail", n))
        rawset(t, n, f)
        return f
    end
})


local function unpack_tail(tbl, ...)
    local count = tbl.n or #tbl
    if count == 0 then return ... end
    return unpack_tail_cache[count](tbl, ...)
end


local function unpack_add(tbl, tail)
    local count = tbl.n or #tbl
    if count == 0 then return tail end
    return unpack_add_cache[count](tbl, tail)
end


local compose_right_cache = setmetatable({
    function(fn1) return fn1 end,
    function(fn1, fn2) return function(...) return fn1(fn2(...)) end end,
    function(fn1, fn2, fn3) return function(...) return fn1(fn2(fn3(...))) end end,
}, {
    __index = function(t, n)
        local template = [[return function(%s) return function(...) return %s(...)%s end end]]

        local tbl_args = {}
        for i = 1,n do
            tbl_args[i] = "fn" .. tostring(i)
        end

        local tbl_calls = {}
        for i = 1,n do
            tbl_calls[i] = tbl_args[n-i+1]
        end

        local arglist = table_concat(tbl_args, ",")
        local fn_front = table_concat(tbl_calls, "(")
        local fn_back = string_rep(")", n-1)
        local name = _chunkname("compose_right", n)
        local f = compile_template(string_format(template, arglist, fn_front, fn_back), name)
        t[n] = f
        return f
    end
})


local compose_left_cache = setmetatable({
    function(fn1) return fn1 end,
    function(fn1, fn2) return function(...) return fn2(fn1(...)) end end,
    function(fn1, fn2, fn3) return function(...) return fn3(fn2(fn1(...))) end end,
}, {
    __index = function(t, n)
        local template = [[return function(%s) return function(...) return %s(...)%s end end]]
        local tbl = {}
        for i = 1,n do
            tbl[i] = "fn" .. tostring(i)
        end
        local arglist = table_concat(tbl, ",")
        local fn_front = table_concat(tbl, "(")
        local fn_back = string_rep(")", n - 1)
        local name = _chunkname("compose_left", n)
        local f = compile_template(string_format(template, arglist, fn_front, fn_back), name)
        t[n] = f
        return f
    end
})


local function nothing()
    -- Nothing --
end


--- Funciton composition, left to right: a, b, c => c(b(a()))
--- @param ... fun(...)
--- @return fun(...)
local function compose_left(...)
    local count = select("#", ...)
    if count == 0 then return nothing end
    return compose_left_cache[count](...)
end


--- Funciton composition, right to left: a, b, c => a(b(c()))
--- @param ... fun(...)
--- @return fun(...)
local function compose_right(...)
    local count = select("#", ...)
    if count == 0 then return nothing end
    return compose_right_cache[count](...)
end


--#region Partial


local function _partial(fn, ...)
    local t = {...}
    local unpacker = unpack_tail_cache[select("#", ...)]
    return function(...)
        return fn(unpacker(t, ...))
    end
end



local partial_cache = setmetatable({
    function(fn, arg1) return function(...) return fn(arg1, ...) end end,
    function(fn, arg1, arg2) return function(...) return fn(arg1, arg2, ...) end end,
    function(fn, arg1, arg2, arg3) return function(...) return fn(arg1, arg2, arg3, ...) end end,
}, {
    __index = function(t, n)
        if n >= 60 then
            return _partial
        end
        local template = [[return function(fn,%s) return function(...) return fn(%s,...) end end]]
        local tbl = {}
        for i = 1,n do
            tbl[i] = "arg" .. tostring(i)
        end
        local arglist = table_concat(tbl, ",")
        local f = compile_template(string_format(template, arglist, arglist), _chunkname("partial", n))
        t[n] = f
        return f
    end
})


local function partial_n_arg_pack(outer, inner)
    return bor(blshift(inner, 16), outer)
end


local function partial_n_arg_unppack(key)
    local outer = band(key, 0xffff)
    local inner = brshift(key, 16)
    return outer, inner
end


local partial_n_cache = setmetatable({}, {
    __index = function(t, key)
        local outer, inner = partial_n_arg_unppack(key)

        if outer >= 60 then
            return _partial
        end

        local template = [[return function(fn,%s) return function(%s) return fn(%s%s%s) end end]]

        local code
        do
            local tbl_outer = {}
            for i = 1,outer do
                tbl_outer[i] = "arg" .. tostring(i)
            end

            local tbl_inner = {}
            for i = 1,inner do
                tbl_inner[i] = "arg" .. tostring(outer + i)
            end

            local inner_arglist = table_concat(tbl_inner, ",")
            local outer_arglist = table_concat(tbl_outer, ",")

            local delim = inner > 0 and "," or ""

            code = string_format(template, outer_arglist, inner_arglist,
                                 outer_arglist, delim, inner_arglist)
        end

        local f = compile_template(code, _chunkname2("partial", outer, inner))
        t[key] = f
        return f
    end
})


--- Generate partial function application with arguments
--- @param fn function
--- @param ... any
--- @return function
local function partial(fn, ...)
    local count = select("#", ...)
    if count == 0 then return fn end
    return partial_cache[count](fn, ...)
end


--- Generate fixed arity partial function application with arguments
--- @param n integer
--- @param fn function
--- @param ... any
--- @return function
local function partial_n(n, fn, ...)
    local count = select("#", ...)
    if count == 0 then return fn end
    return partial_n_cache[partial_n_arg_pack(count, n)](fn, ...)
end


--#endregion Partial

return {
    pack = pack,

    unpack = this_unpack,
    unpack_tail = unpack_tail,
    unpack_add = unpack_add,

    compose = compose_left,
    compose_left = compose_left,
    compose_right = compose_right,

    partial = partial,
    partial_n = partial_n,
}
