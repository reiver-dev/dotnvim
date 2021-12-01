--- Iterator class

local function to_string()
  return "<iterator>"
end


--- @generic STATE, IDX, VAL: ...
--- @param self Iterator<IDX, VAL>
--- @return fun(state: STATE, idx: IDX): IDX, VAL
--- @return STATE
--- @return IDX?
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

local raw_iter = require "fun.iter"
local raw_str = require "fun.str"
local raw_range = require "fun.range"

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

--- @generic STATE, IDX, VAL: ...
--- @param it fun(state: STATE, idx: IDX): IDX, VAL
--- @return Iterator<IDX, VAL>
--- @overload fun(it: string): Iterator<integer, string>
--- @overload fun(it: table): Iterator
--- @overload fun(it: Iterator): Iterator
local function from(it, state, idx)
    return setmetatable(wrap(it, state, idx), iterator_mt)
end

--- @generic STATE, IDX, VAL: ...
--- @param it Iterator<IDX, VAL>
--- @return fun(state: STATE, idx: IDX): IDX, VAL
--- @return STATE
--- @return IDX?
local function iter(it, state, idx)
    return unwrap(it, state, idx)
end


----- @generic STATE, IDX, VAL: ..., F: function
----- @param iter F(state: STATE, idx: IDX): IDX, VAL
----- @param state STATE
----- @param idx? IDX
----- @return Iterator<IDX, VAL>
local function new(iter, state, idx)
    return setmetatable({iter, state, idx}, iterator_mt)
end


--- @generic STATE, IDX, VAL: ...
--- @param self Iterator<IDX, VAL>
--- @return fun(state: STATE, idx: IDX): IDX, VAL
--- @return STATE
--- @return IDX?
function cls:iter()
    return self[1], self[2], self[3]
end

--- @generic T: Iterator
--- @param self T
--- @return T
function cls:copy()
    return setmetatable({self[1], self[2], self[3]}, iterator_mt)
end


local function step_impl(self, ...)
    self[3] = select(1, ...)
    return ...
end


--- @generic IDX, VAL: ...
--- @param self Iterator<IDX, VAL>
--- @return IDX Index
--- @return VAL Value
function cls:step()
    return step_impl(self, self[1](self[2], self[3]))
end


local function next_impl(iter, state, idx, ...)
    return setmetatable({iter, state, idx}, iterator_mt), ...
end


--- @generic T: Iterator, IDX, VAL: ...
--- @param self T
--- @return T Iterator
--- @return VAL Value
function cls:next()
    return next_impl(self[1], self[2], self[1](self[2], self[3]))
end


--#region Imports

local _map = raw_iter.map
local _map_kv = raw_iter.map_kv
local _fold = raw_iter.fold
local _reduce = raw_iter.reduce
local _any = raw_iter.any
local _all = raw_iter.all
local _each = raw_iter.each
local _each_kv = raw_iter.each_kv
local _filter = raw_iter.filter
local _filter1 = raw_iter.filter1
local _filter_kv = raw_iter.filter_kv
local _filter1_kv = raw_iter.filter1_kv
local _reject = raw_iter.reject
local _reject1 = raw_iter.reject1
local _reject_kv = raw_iter.reject_kv
local _reject1_kv = raw_iter.reject1_kv
local _take = raw_iter.take
local _take_one = raw_iter.take_one
local _take_while = raw_iter.take_while
local _take_while_kv = raw_iter.take_while_kv
local _kv = raw_iter.kv
local _find = raw_iter.find
local _find_kv = raw_iter.find_kv
local _extract = raw_iter.extract
local _new_array = raw_iter.new_array
local _new_seq = raw_iter.new_seq
local _new_kv = raw_iter.new_kv
local _new_pairs = raw_iter.new_pairs
local _into_array = raw_iter.into_array
local _into_seq = raw_iter.into_seq
local _into_kv = raw_iter.into_kv
local _into_pairs = raw_iter.into_pairs
local _unit = raw_iter.unit
local _always = raw_iter.always
local _never = raw_iter.never
local _ntimes = raw_iter.ntimes
local _enumerate = raw_iter.enumerate
local _chain = raw_iter.chain
local _zip = raw_iter.zip

local _chars = raw_str.chars
local _bytes = raw_str.bytes
local _rchars = raw_str.chars_reversed
local _rbytes = raw_str.bytes_reversed
local _split = raw_str.split
local _splitpat = raw_str.split_pattern
local _utf8 = raw_str.utf8
local _rutf8 = raw_str.rutf8
local _utf8_pos = raw_str.utf8_pos
local _rutf8_pos = raw_str.rutf8_pos

local _range = raw_range.range
local _erange = raw_range.erange
local _irange = raw_range.irange

--#endregion


--#region Constructors

local function unit(val)
    return new(_unit(val))
end


--- @generic VAL
--- @param val VAL
--- @return Iterator<any, VAL>
local function always(val)
    return new(_always(val))
end


--- @return Iterator
local function never()
    return new(_never())
end


--- @generic VAL
--- @param n integer
--- @param val VAL
--- @return Iterator<any, VAL>
local function ntimes(n, val)
    return new(_ntimes(n))
end


--- Inclusive number range [start, stop)
--- @param start number
--- @param stop number
--- @param step? number
--- @return fun(state: any, idx: integer): integer, number
--- @return any state
--- @return integer idx
local function range(start, stop, step)
    return new(_range(start, stop, step))
end


--- Exclusive number range [start, stop)
--- @param start number
--- @param stop number
--- @param step? number
--- @return fun(state: any, idx: integer): integer, number
--- @return any state
--- @return integer idx
local function erange(start, stop, step)
    return new(_erange(start, stop, step))
end


--- Integer inclusive range [start, stop]
--- @param start integer
--- @param stop? integer
--- @param step? integer
--- @return fun(state: any, idx: integer): integer, integer
--- @return any state
--- @return integer idx
local function irange(start, stop, step)
    return new(_irange(start, stop, step))
end


local function string_chars(text)
    return new(_chars(text))
end


local function string_bytes(text)
    return new(_bytes(text))
end


local function string_rchars(text)
    return new(_rchars(text))
end


local function string_rbytes(text)
    return new(_rbytes(text))
end


local function string_split(separator, text)
    return new(_split(separator, text))
end


local function string_split_pattern(separator, text)
    return new(_splitpat(separator, text))
end


--- @param text string
--- @return Iterator<integer, string>
local function utf8(text)
    return new(_utf8(text))
end


--- @param text string
--- @return Iterator<integer, string>
local function rutf8(text)
    return new(_rutf8(text))
end


--- @param text string
--- @return Iterator
local function utf8_pos(text)
    return new(_utf8_pos(text))
end


--- @param text string
--- @return Iterator
local function rutf8_pos(text)
    return new(_rutf8_pos(text))
end

--#endregion


--#region Adapters

--- @generic IDX, A, B
--- @param self Iterator<IDX, A>
--- @param fn fun(val: A): B
--- @return Iterator<IDX, B>
function cls:map(fn)
    return new(_map(fn, self[1], self[2], self[3]))
end


--- @generic A, B, IDX
--- @param self Iterator<IDX, A>
--- @param fn fun(idx, IDX, arg: A): B
--- @return Iterator<IDX, B>
function cls:map_kv(fn)
    return new(_map_kv(fn, self[1], self[2], self[3]))
end


--- @generic ACC, VAL
--- @param self Iterator<any, VAL>
--- @param fn fun(acc: ACC, val: VAL): ACC
--- @param acc ACC
--- @return ACC
function cls:fold(fn, acc)
    return _fold(fn, acc, self[1], self[2], self[3])
end


--- @generic ACC, VAL
--- @param self Iterator<any, VAL>
--- @param fn fun(acc: VAL, val: VAL): VAL
--- @return VAL
function cls:reduce(fn)
    return _reduce(fn, self[1], self[2], self[3])
end


--- @generic VAL
--- @param self Iterator<any, VAL>
--- @param fn fun(val: VAL): boolean
--- @return boolean
function cls:any(fn)
    return _any(fn, self[1], self[2], self[3])
end


--- @generic VAL
--- @param self Iterator<any, VAL>
--- @param fn fun(val: VAL): boolean
--- @return boolean
function cls:all(fn)
    return _all(fn, self[1], self[2], self[3])
end


--- @generic VAL
--- @param self Iterator<any, VAL>
--- @param fn fun(val: VAL)
function cls:each(fn)
    return _each(fn, self[1], self[2], self[3])
end


--- @generic IDX, VAL
--- @param self Iterator<IDX, VAL>
--- @param fn fun(idx: IDX, val: VAL)
function cls:each_kv(fn)
    return _each_kv(fn, self[1], self[2], self[3])
end


--- @generic VAL, T: Iterator
--- @param self T
--- @param fn fun(val: VAL): boolean
--- @return T
function cls:filter(fn)
    return new(_filter(fn, self[1], self[2], self[3]))
end


--- @generic VAL, IDX, T: Iterator
--- @param self T
--- @param fn fun(idx: IDX, val: VAL): boolean
--- @return T
function cls:filter_kv(fn)
    return new(_filter_kv(fn, self[1], self[2], self[3]))
end


--- @generic VAL, T: Iterator
--- @param self T
--- @param fn fun(val: VAL): boolean
--- @return T
function cls:filter1(fn)
    return new(_filter1(fn, self[1], self[2], self[3]))
end


--- @generic VAL, IDX, T: Iterator
--- @param self T
--- @param fn fun(idx: IDX, val: VAL): boolean
--- @return T
function cls:filter1_kv(fn)
    return new(_filter1_kv(fn, self[1], self[2], self[3]))
end


--- @generic VAL, T: Iterator
--- @param self T
--- @param fn fun(val: VAL): boolean
--- @return T
function cls:reject(fn)
    return new(_reject(fn, self[1], self[2], self[3]))
end


--- @generic VAL, IDX, T: Iterator
--- @param self T
--- @param fn fun(idx: IDX, val: VAL): boolean
--- @return T
function cls:reject_kv(fn)
    return new(_reject_kv(fn, self[1], self[2], self[3]))
end


--- @generic VAL, T: Iterator
--- @param self T
--- @param fn fun(val: VAL): boolean
--- @return T
function cls:reject1(fn)
    return new(_reject1(fn, self[1], self[2], self[3]))
end


--- @generic VAL, IDX, T: Iterator
--- @param self T
--- @param fn fun(idx: IDX, val: VAL): boolean
--- @return T
function cls:reject1_kv(fn)
    return new(_reject1_kv(fn, self[1], self[2], self[3]))
end


--- @generic T: Iterator
--- @param self T
--- @param n integer
--- @return T
function cls:take(n)
    return new(_take(n, self[1], self[2], self[3]))
end


--- @generic T: Iterator
--- @param self T
--- @return T
function cls:take_one()
    return new(_take_one(self[1], self[2], self[3]))
end


--- @generic IDX, VAL
--- @param self Iterator<IDX, VAL>
--- @param fn fun(val: VAL): boolean
--- @return Iterator<IDX, VAL>
function cls:take_while(fn)
    return new(_take_while(fn, self[1], self[2], self[3]))
end


--- @generic IDX, VAL
--- @param self Iterator<IDX, VAL>
--- @param fn fun(idx, IDX, val: VAL): boolean
--- @return Iterator<IDX, VAL>
function cls:take_while_kv(fn)
    return new(_take_while_kv(fn, self[1], self[2], self[3]))
end


--- @param self Iterator
--- @return Iterator
function cls:kv()
    return new(_kv(self[1], self[2], self[3]))
end


--- @param self Iterator
--- @return Iterator
function cls:enumerate()
    return new(_enumerate(self[1], self[2], self[3]))
end


--- @generic IDX, VAL
--- @param self Iterator<any, IDX>
--- @param tbl table<IDX, VAL>
--- @return Iterator
function cls:extract(tbl)
    return new(_extract(tbl, self[1], self[2], self[3]))
end

--#endregion


--#region Finalizers

--- @generic VAL, T: Iterator
--- @param self Iterator<any, VAL>
--- @param fn fun(val: VAL): boolean
--- @return VAL
function cls:find(fn)
    return _find(fn, self[1], self[2], self[3])
end


--- @generic IDX, VAL
--- @param self Iterator<IDX, VAL>
--- @param fn fun(idx: IDX, val: VAL): boolean
--- @return VAL
function cls:find_kv(fn)
    return _find_kv(fn, self[1], self[2], self[3])
end


--- @generic VAL
--- @param self Iterator<any, VAL>
--- @return VAL[]
function cls:new_array()
    return _new_array(self[1], self[2], self[3])
end


--- @generic VAL
--- @param self Iterator<any, VAL>
--- @return VAL[]
function cls:new_seq()
    return _new_seq(self[1], self[2], self[3])
end


--- @generic IDX, VAL
--- @param self Iterator<IDX, VAL>
--- @return table<IDX, VAL>
function cls:new_kv()
    return _new_kv(self[1], self[2], self[3])
end


--- @param self Iterator
--- @return table
function cls:new_pairs()
    return _new_pairs(self[1], self[2], self[3])
end


--- @generic T: table
--- @param self Iterator
--- @param tbl T
--- @param at? integer
--- @return T
function cls:into_array(tbl, at)
    return _into_array(tbl, at, self[1], self[2], self[3])
end


--- @generic T: table
--- @param self Iterator
--- @param tbl T
--- @param at? integer
--- @return T
function cls:into_seq(tbl, at)
    return _into_seq(tbl, at, self[1], self[2], self[3])
end


--- @generic T: table
--- @param self Iterator
--- @param tbl T
--- @return T
function cls:into_kv(tbl)
    return _into_kv(tbl, self[1], self[2], self[3])
end


--- @generic T: table
--- @param self Iterator
--- @param tbl T
--- @return T
function cls:into_pairs(tbl)
    return _into_pairs(tbl, self[1], self[2], self[3])
end

--#endregion


--#region Combinators

--- @param self Iterator
--- @param ... Iterator
--- @return Iterator
function cls:chain(...)
    return _chain(self, ...)
end


--- @param self Iterator
--- @param ... Iterator
--- @return Iterator
function cls:zip(...)
    return _zip(self, ...)
end

--#endregion


return {
    iter = iter,
    new = new,
    from = from,

    unit = unit,
    always = always,
    never = never,
    ntimes = ntimes,

    range = range,
    erange = erange,
    irange = irange,

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
