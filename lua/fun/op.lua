--- Operators

local MODULE = ...

local table_concat = table.concat
local string_format = string.format
local string_rep = string.rep


local function _tostring(num)
    return string_format("tostring(arg%d)", num)
end


local function _arg(num)
    return "arg" .. tostring(num)
end


local function _iarg(num)
    local s = tostring(num)
    return s .. ",arg" .. s
end


local function argtable(fmt, count)
    local tbl = {}
    for i = 1,count do
        tbl[i] = fmt(i)
    end
    return tbl
end


local function make_operator_template(op, arity)
    local base = [[return function(%s) return %s end]]
    local tbl = argtable(_arg, arity)
    local arguments = table_concat(tbl, ",", 1, arity)
    local expression = table_concat(tbl, op, 1, arity)
    return string_format(base, arguments, expression)
end


local function make_joinsep_template(arity)
    local base = [[return function(sep,%s) return %s end]]
    local tbl_args = argtable(_arg, arity)
    local arguments = table_concat(tbl_args, ",", 1, arity)
    local expression = table_concat(tbl_args, "..sep..", 1, arity)
    return string_format(base, arguments, expression)
end


local function make_strcat_template(arity)
    local base = [[return function(%s) return %s end]]
    local tbl_args = argtable(_arg, arity)
    local tbl_str = argtable(_tostring, arity)
    local arguments = table_concat(tbl_args, ",", 1, arity)
    local expression = table_concat(tbl_str, "..", 1, arity)
    return string_format(base, arguments, expression)
end


local function make_strjoin_template(arity)
    local base = [[return function(sep,%s) return %s end]]
    local tbl_args = argtable(_arg, arity)
    local tbl_str = argtable(_tostring, arity)
    local arguments = table_concat(tbl_args, ",", 1, arity)
    local expression = table_concat(tbl_str, "..sep..", 1, arity)
    return string_format(base, arguments, expression)
end


local function make_fold_template(arity)
    local base = [[return function(fn, acc, %s) return %sacc,%s end]]
    local tbl_args = argtable(_arg, arity)
    local arguments = table_concat(tbl_args, ",", 1, arity)
    local expr_prefix =  string_rep("fn(", arity)
    local expr_suffix =  table_concat(tbl_args, ")," , 1, arity)
    return string_format(base, arguments, expr_prefix, expr_suffix)
end


local function make_ifold_template(arity)
    local base = [[return function(fn, acc, %s) return %sacc,%s end]]
    local tbl_args = argtable(_arg, arity)
    local tbl_iargs = argtable(_iarg, arity)
    local arguments = table_concat(tbl_args, ",", 1, arity)
    local expr_prefix =  string_rep("fn(", arity)
    local expr_suffix =  table_concat(tbl_iargs, ")," , 1, arity)
    return string_format(base, arguments, expr_prefix, expr_suffix)
end


local function partial1(fn, arg1)
    return function(arg2)
        return fn(arg1, arg2)
    end
end


local function identity(arg)
    return arg
end


local function nothing()
    -- Nothing --
end


local function compile_template(text, name)
    local res, err = loadstring(text, name)
    if res then
        return res()
    else
        error(err)
    end
end


--- @param name string
--- @param constructor fun(arity: integer):string
--- @param init table?
--- @return table<integer, fun(...)>
local function MakeOperator(name, constructor, init)
    local chunkname = string_format("=%s.%s(%%d)", MODULE, name)
    if not init then init = {identity} end
    return setmetatable(init, {
        __index = function(t, n)
            if n == 0 then return nothing end
            local f = compile_template(constructor(n), string_format(chunkname, n))
            rawset(t, n, f)
            return f
        end
    })
end



local _add = MakeOperator("_add", partial1(make_operator_template, "+"))
local _sub = MakeOperator("_sub", partial1(make_operator_template, "-"))
local _mul = MakeOperator("_mul", partial1(make_operator_template, "*"))
local _div = MakeOperator("_div", partial1(make_operator_template, "/"))
local _mod = MakeOperator("_mod", partial1(make_operator_template, "%"))
local _and = MakeOperator("_and", partial1(make_operator_template, "and"))
local _or = MakeOperator("_or", partial1(make_operator_template, "or"))
local _concat = MakeOperator("_concat", partial1(make_operator_template, ".."))
local _join = MakeOperator("_join", make_joinsep_template)

local _strcat = MakeOperator("_strcat", make_strcat_template, {tostring})
local _strjoin = MakeOperator("_strjoin", make_strjoin_template, {tostring})

local _fold = MakeOperator("_fold", make_fold_template, {function(fn, acc, arg1) return fn(acc, arg1) end})
local _ifold = MakeOperator("_ifold", make_ifold_template, {function(fn, acc, arg1) return fn(acc, 1, arg1) end})


local function add(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _add[count](...)
end


local function sub(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _sub[count](...)
end


local function mul(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _mul[count](...)
end


local function div(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _div[count](...)
end


local function mod(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _mod[count](...)
end


local function all(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _and[count](...)
end


local function any(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _or[count](...)
end


local function concat(...)
    local count = select("#", ...)
    if count == 0 then return 0 end
    return _concat[count](...)
end


local function join(sep, ...)
    local count = select("#", ...)
    if count == 0 then return "" end
    return _join[count](sep, ...)
end


local function strcat(...)
    local count = select("#", ...)
    if count == 0 then return "" end
    return _strcat[count](...)
end


local function strjoin(sep, ...)
    local count = select("#", ...)
    if count == 0 then return "" end
    return _strjoin[count](sep, ...)
end


local function fold(fn, acc, ...)
    local count = select("#", ...)
    if count == 0 then return acc end
    return _fold[count](fn, acc, ...)
end


local function ifold(fn, acc, ...)
    local count = select("#", ...)
    if count == 0 then return acc end
    return _ifold[count](fn, acc, ...)
end


local function fixed_add(arity)
    if arity == nil then return add end
    return _add[arity]
end


local function fixed_sub(arity)
    if arity == nil then return sub end
    return _sub[arity]
end


local function fixed_mul(arity)
    if arity == nil then return mul end
    return _mul[arity]
end


local function fixed_div(arity)
    if arity == nil then return div end
    return _div[arity]
end


local function fixed_mod(arity)
    if arity == nil then return mod end
    return _mod[arity]
end


local function fixed_all(arity)
    if arity == nil then return all end
    return _and[arity]
end


local function fixed_any(arity)
    if arity == nil then return any end
    return _or[arity]
end


local function fixed_concat(arity)
    if arity == nil then return concat end
    return _concat[arity]
end


local function fixed_join(arity)
    if arity == nil then return join end
    return _join[arity]
end


local function fixed_strcat(arity)
    if arity == nil then return strcat end
    return _strcat[arity]
end


local function fixed_strjoin(arity)
    if arity == nil then return strjoin end
    return _strjoin[arity]
end


local function fixed_fold(arity)
    if arity == nil then return fold end
    return _fold[arity]
end


local function fixed_ifold(arity)
    if arity == nil then return ifold end
    return _ifold[arity]
end


return {
    var = {
        add = add,
        sub = sub,
        mul = mul,
        div = div,
        mod = mod,
        all = all,
        any = any,
        concat = concat,
        join = join,
        strcat = strcat,
        strjoin = strjoin,
        fold = fold,
        ifold = ifold,
    },
    fixed = {
        add = fixed_add,
        sub = fixed_sub,
        mul = fixed_mul,
        div = fixed_div,
        mod = fixed_mod,
        all = fixed_all,
        any = fixed_any,
        concat = fixed_concat,
        join = fixed_join,
        strcat = fixed_strcat,
        strjoin = fixed_strjoin,
        fold = fixed_fold,
        ifold = fixed_ifold,
    }
}
