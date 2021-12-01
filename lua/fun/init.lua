local _iter = require "fun.iter"
local _wrap = require "fun.wrap"
local _op = require "fun.op"
local _vararg = require "fun.vararg"


return {
    iter = _wrap.iter,
    new = _wrap.new,
    from = _wrap.from,

    unit = _wrap.unit,
    always = _wrap.always,
    never = _wrap.never,
    ntimes = _wrap.ntimes,

    range = _wrap.range,
    erange = _wrap.erange,
    irange = _wrap.irange,

    string = {
        chars = _wrap.string_chars,
        bytes = _wrap.string_bytes,
        rchars = _wrap.string_rchars,
        rbytes = _wrap.string_rbytes,
        split = _wrap.string_split,
        splitpat = _wrap.string_split_pattern,
        utf8 = _wrap.utf8,
        rutf8 = _wrap.rutf8,
        utf8_pos = _wrap.utf8_pos,
        rutf8_pos = _wrap.rutf8_pos,
    },

    op = _op.fixed,
    strcat = _op.var.strcat,
    strjoin = _op.var.strjoin,

    pack = _vararg.pack,
    unpack = _vararg.unpack,
    partial = _vararg.partial,
    compose = _vararg.compose,

    raw = _iter,
}
