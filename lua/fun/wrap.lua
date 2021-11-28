--- Iterator class

local function to_string()
  return "<iterator>"
end


local function self_iterate(self)
  return self[1], self[2], self[3]
end


--- @class Iterator
local cls = {}

local iterator_mt = {
    __index = cls,
    __call = self_iterate,
    __tostring = to_string,
}

local raw = require "fun.iter"
local raw_str = require "fun.str"

local utf8 = raw_str.utf8

local function unwrap(it, state, idx)
    if type(it) == "function" then
        return it, state, idx
    elseif type(it) == "table" then
        if iterator_mt == getmetatable(it) then
            return it[1], it[2], it[3]
        elseif it[1] == nil then
            return pairs(it)
        else
            return ipairs(it)
        end
    elseif type(it) == "string" then
        return {utf8(it)}
    end
    return error("Unsupported iterator type: " .. type(it))
end


local function wrap(it, state, idx)
    if type(it) == "function" then
        return {it, state, idx}
    elseif type(it) == "table" then
        if iterator_mt == getmetatable(it) then
            return it
        elseif it[1] == nil then
            return {pairs(it)}
        else
            return {ipairs(it)}
        end
    elseif type(it) == "string" then
        return {utf8(it)}
    end
    return error("Unsupported iterator type: " .. type(it))
end

--- @generic S, I, V
--- @param it fun(state: S, idx: I): I, V
--- @return Iterator
--- @overload fun(it: string): Iterator
--- @overload fun(it: table): Iterator
--- @overload fun(it: Iterator): Iterator
local function new(it, state, idx)
    return setmetatable(wrap(it, state, idx), iterator_mt)
end


local function iter(it, state, idx)
    return unwrap(it, state, idx)
end


local function make(iter, state, idx)
    return setmetatable({iter, state, idx}, iterator_mt)
end


--#region Imports

local _map = raw.map
local _map_kv = raw.map_kv
local _fold = raw.fold
local _reduce = raw.reduce
local _any = raw.any
local _all = raw.all
local _each = raw.each
local _each_kv = raw.each_kv
local _filter = raw.filter
local _filter1 = raw.filter1
local _filter_kv = raw.filter_kv
local _filter1_kv = raw.filter1_kv
local _reject = raw.reject
local _reject1 = raw.reject1
local _reject_kv = raw.reject_kv
local _reject1_kv = raw.reject1_kv
local _take = raw.take
local _take_one = raw.take_one
local _take_while = raw.take_while
local _take_while_kv = raw.take_while_kv
local _kv = raw.kv
local _find = raw.find
local _find_kv = raw.find_kv
local _extract = raw.extract
local _new_array = raw.new_array
local _new_seq = raw.new_seq
local _new_kv = raw.new_kv
local _new_pairs = raw.new_pairs
local _into_array = raw.into_array
local _into_seq = raw.into_seq
local _into_kv = raw.into_kv
local _into_pairs = raw.into_pairs
local _unit = raw.unit
local _always = raw.always
local _never = raw.never
local _ntimes = raw.ntimes
local _enumerate = raw.enumerate
local _chain = raw.chain
local _zip = raw.zip

local _chars = raw_str.string_chars
local _bytes = raw_str.string_bytes
local _rchars = raw_str.string_chars_reversed
local _rbytes = raw_str.string_bytes_reversed
local _split = raw_str.string_split
local _splitpat = raw_str.string_split_pattern
local _utf8 = raw_str.utf8
local _rutf8 = raw_str.rutf8
local _utf8_pos = raw_str.utf8_pos
local _rutf8_pos = raw_str.rutf8_pos

--#endregion


--#region Constructors

local function unit(val)
    return make(_unit(val))
end


local function always(val)
    return make(_always(val))
end


local function never()
    return make(_never())
end


local function ntimes(n)
    return make(_ntimes(n))
end


local function string_chars(text)
    return make(_chars(text))
end


local function string_bytes(text)
    return make(_bytes(text))
end


local function string_rchars(text)
    return make(_rchars(text))
end


local function string_rbytes(text)
    return make(_rbytes(text))
end


local function string_split(separator, text)
    return make(_split(separator, text))
end


local function string_split_pattern(separator, text)
    return make(_splitpat(separator, text))
end


local function utf8(text)
    return make(_utf8(text))
end


local function rutf8(text)
    return make(_rutf8(text))
end


local function utf8_pos(text)
    return make(_utf8_pos(text))
end


local function rutf8_pos(text)
    return make(_rutf8_pos(text))
end

--#endregion


--- @generic A, B, T: Iterator
--- @param self T
--- @param fn fun(arg: A): B
--- @return Iterator
function cls:map(fn)
    return make(_map(fn, self[1], self[2], self[3]))
end


function cls:map_kv(fn)
    return make(_map_kv(fn, self[1], self[2], self[3]))
end


function cls:fold(fn, acc)
    return _fold(fn, acc, self[1], self[2], self[3])
end


function cls:reduce(fn)
    return _reduce(fn, self[1], self[2], self[3])
end


function cls:any(fn)
    return _any(fn, self[1], self[2], self[3])
end


function cls:all(fn)
    return _all(fn, self[1], self[2], self[3])
end


function cls:each(fn)
    return _each(fn, self[1], self[2], self[3])
end


function cls:each_kv(fn)
    return _each_kv(fn, self[1], self[2], self[3])
end


function cls:filter(fn)
    return make(_filter(fn, self[1], self[2], self[3]))
end


function cls:filter_kv(fn)
    return make(_filter_kv(fn, self[1], self[2], self[3]))
end


function cls:filter1(fn)
    return make(_filter1(fn, self[1], self[2], self[3]))
end


function cls:filter1_kv(fn)
    return make(_filter1_kv(fn, self[1], self[2], self[3]))
end


function cls:reject(fn)
    return make(_reject(fn, self[1], self[2], self[3]))
end


function cls:reject_kv(fn)
    return make(_reject_kv(fn, self[1], self[2], self[3]))
end


function cls:reject1(fn)
    return make(_reject1(fn, self[1], self[2], self[3]))
end


function cls:reject1_kv(fn)
    return make(_reject1_kv(fn, self[1], self[2], self[3]))
end


function cls:take(n)
    return make(_take(n, self[1], self[2], self[3]))
end


function cls:take_one()
    return make(_take_one(self[1], self[2], self[3]))
end


function cls:take_while(fn)
    return make(_take_while(fn, self[1], self[2], self[3]))
end


function cls:take_while_kv(fn)
    return make(_take_while_kv(fn, self[1], self[2], self[3]))
end


function cls:kv()
    return make(_kv(self[1], self[2], self[3]))
end


function cls:find(fn)
    return _find(fn, self[1], self[2], self[3])
end


function cls:find_kv(fn)
    return _find_kv(fn, self[1], self[2], self[3])
end


function cls:extract(tbl)
    return make(_extract(tbl, self[1], self[2], self[3]))
end


function cls:new_array()
    return _new_array(self[1], self[2], self[3])
end


function cls:new_seq()
    return _new_seq(self[1], self[2], self[3])
end


function cls:new_kv()
    return _new_kv(self[1], self[2], self[3])
end


function cls:new_pairs()
    return _new_pairs(self[1], self[2], self[3])
end


function cls:into_array(tbl, at)
    return _into_array(tbl, at, self[1], self[2], self[3])
end


function cls:into_seq(tbl, at)
    return _into_seq(tbl, at, self[1], self[2], self[3])
end


function cls:into_kv(tbl)
    return _into_kv(tbl, self[1], self[2], self[3])
end


function cls:into_pairs(tbl)
    return _into_pairs(tbl, self[1], self[2], self[3])
end


function cls:enumerate()
    return _enumerate(self[1], self[2], self[3])
end


function cls:chain(...)
    return _chain(self, ...)
end


function cls:zip(...)
    return _zip(self, ...)
end


return {
    iter = iter,
    new = new,

    unit = unit,
    always = always,
    never = never,
    ntimes = ntimes,

    string_chars = string_chars,
    string_bytes = string_bytes,
    string_rchars = string_rchars,
    string_rbytes = string_rbytes,
    string_split = string_split,
    string_split_pattern = string_split_pattern,
    utf8 = utf8,
    rutf8 = rutf8,
    utf8_pos = utf8_pos,
    rutf8_pos = rutf8_pos,
}
