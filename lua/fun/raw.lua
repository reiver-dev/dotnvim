local _iter = require "fun.iter"
local _str = require "fun.str"
local _range = require "fun.range"
local _vararg = require "fun.vararg"

return {
    -- Main

    map = _iter.map,
    map_kv = _iter.map_kv,
    ["map-kv"] = _iter.map_kv,

    fold = _iter.fold,
    reduce = _iter.reduce,
    any = _iter.any,
    all = _iter.all,
    count = _iter.count,

    foreach = _iter.foreach,
    foreach_kv = _iter.foreach_kv,
    ["foreach-kv"] = _iter.foreach_kv,

    filter = _iter.filter,
    filter1 = _iter.filter1,
    filter_kv = _iter.filter_kv,
    filter1_kv = _iter.filter1_kv,
    ["filter-kv"] = _iter.filter_kv,
    ["filter1-kv"] = _iter.filter1_kv,

    reject = _iter.reject,
    reject1 = _iter.reject1,
    reject_kv = _iter.reject_kv,
    reject1_kv = _iter.reject1_kv,
    ["reject-kv"] = _iter.reject_kv,
    ["reject1-kv"] = _iter.reject1_kv,

    filtermap = _iter.filtermap,
    filtermap_kv = _iter.filtermap_kv,
    ["filtermap-kv"] = _iter.filtermap_kv,

    take = _iter.take,
    take_one = _iter.take_one,
    take_while = _iter.take_while,
    take_while_kv = _iter.take_while_kv,
    ["take-one"] = _iter.take_one,
    ["take-while"] = _iter.take_while,
    ["take-while-kv"] = _iter.take_while_kv,

    kv = _iter.kv,
    pairs = _iter.pairs,
    ipairs = _iter.ipairs,
    rpairs = _iter.rpairs,
    stateful = _iter.stateful,
    extract = _iter.extract,

    find = _iter.find,
    ["find-kv"] = _iter.find_kv,

    new_array = _iter.new_array,
    new_seq = _iter.new_seq,
    new_kv = _iter.new_kv,
    new_pairs = _iter.new_pairs,

    ["new-array"] = _iter.new_array,
    ["new-seq"] = _iter.new_seq,
    ["new-kv"] = _iter.new_kv,
    ["new-pairs"] = _iter.new_pairs,

    into_array = _iter.into_array,
    into_seq = _iter.into_seq,
    into_kv = _iter.into_kv,
    into_pairs = _iter.into_pairs,

    ["into-array"] = _iter.into_array,
    ["into-seq"] = _iter.into_seq,
    ["into-kv"] = _iter.into_kv,
    ["into-pairs"] = _iter.into_pairs,

    unit = _iter.unit,
    always = _iter.always,
    never = _iter.never,
    ntimes = _iter.ntimes,
    enumerate = _iter.enumerate,
    chain = _iter.chain,
    flatmap = _iter.flatmap,
    zip = _iter.zip,

    -- Ranges

    range = _range.range,
    erange = _range.erange,
    irange = _range.irange,

    -- Vararg

    pack = _vararg.pack,
    unpack = _vararg.unpack,
    partial = _vararg.partial,
    compose = _vararg.compose,

    -- String

    str_chars = _str.chars,
    str_bytes = _str.bytes,
    str_rchars = _str.chars_reversed,
    str_rbytes = _str.bytes_reversed,
    str_split = _str.split,
    str_splitpat = _str.split_pattern,
    str_utf8 = _str.utf8,
    str_rutf8 = _str.rutf8,
    str_utf8_pos = _str.utf8_pos,
    str_rutf8_pos = _str.rutf8_pos,

    ["str-chars"] = _str.chars,
    ["str-bytes"] = _str.bytes,
    ["str-rchars"] = _str.chars_reversed,
    ["str-rbytes"] = _str.bytes_reversed,
    ["str-split"] = _str.split,
    ["str-splitpat"] = _str.split_pattern,
    ["str-utf8"] = _str.utf8,
    ["str-rutf8"] = _str.rutf8,
    ["str-utf8-pos"] = _str.utf8_pos,
    ["str-rutf8-pos"] = _str.rutf8_pos,
}
