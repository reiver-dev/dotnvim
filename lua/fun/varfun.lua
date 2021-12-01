--- Recursive vararg reductions

local function foldl_recur(i, fun, acc, val, ...)
  if i == 0 then
    return fun(acc, val)
  else
    return foldl_recur((i - 1), fun, fun(acc, val), ...)
  end
end


--- @generic A, V
--- @param fn fun(acc: A, val: V): A
--- @param acc A
--- @param ... V
local function foldl(fn, acc, ...)
  local i = select("#", ...)
  if i == 0 then
    return acc
  else
    return foldl_recur(i - 1, fn, acc, ...)
  end
end


local function foldr_recur(i, fun, val, ...)
  if (i == 0) then
    return val
  else
    return fun(val, foldr_recur(i - 1, fun, ...))
  end
end


--- @generic V
--- @param fn fun(acc: V, val: V): V
--- @param ... V
local function foldr(fn, val, ...)
  return foldr_recur(select("#", ...), fn, val, ...)
end


local function foreach_recur(i, fn, val, ...)
  if i == 0 then
    return fn(val)
  else
    fn(val)
    return foreach_recur(i - 1, fn, ...)
  end
end



--- @generic V
--- @param fn fun(val: V): V
--- @param ... V
local function foreach(fn, ...)
  local i = select("#", ...)
  if i == 0 then
    return nil
  else
    return foreach_recur(i - 1, fn, ...)
  end
end


local function all_recur(i, fn, val, ...)
  if i == 1 then
    return fn(val)
  else
    if fn(val) then
      return all_recur(i - 1, fn, ...)
    else
      return false
    end
  end
end


local function any_recur(i, fun, val, ...)
  if i == 1 then
    return fun(val)
  else
    if fun(val) then
      return true
    else
      return any_recur(i - 1, fun, ...)
    end
  end
end


--- @generic V
--- @param fn fun(val: V): boolean
--- @param ... V
local function all(fn, ...)
  local i = select("#", ...)
  if i == 0 then
    return false
  elseif i == 1 then
    local val = ...
    return fn(val)
  else
    return all_recur(i, fn, ...)
  end
end


--- @generic V
--- @param fn fun(val: V): boolean
--- @param ... V
local function any(fn, ...)
  local i = select("#", ...)
  if (i == 0) then
    return false
  elseif (i == 1) then
    local val = ...
    return fn(val)
  else
    return any_recur(i, fn, ...)
  end
end


local function efoldl_recur(i, n, fun, acc, val, ...)
  if (i == 0) then
    return fun(acc, n, val)
  else
    return efoldl_recur((i - 1), (n + 1), fun, fun(acc, n, val), ...)
  end
end


--- @generic A, V
--- @param fn fun(acc: A, val: V): boolean, A
--- @param acc A
--- @param ... V
local function efoldl(fn, acc, ...)
  local i = select("#", ...)
  if (i == 0) then
    return acc
  else
    return efoldl_recur((i - 1), 1, fn, acc, ...)
  end
end


local function pfoldl_recur(i, fn, acc, val, ...)
  if (i == 0) then
    return fn(acc, val)
  else
    local cont, acc0 = fn(acc, val)
    if cont then
      return pfoldl_recur((i - 1), acc0, ...)
    else
      return false, acc0
    end
  end
end


--- @generic A, V
--- @param fn fun(acc: A, val: V): boolean, A
--- @param acc A
--- @param ... V
local function pfoldl(fn, acc, ...)
  local i = select("#", ...)
  if i == 0 then
    return false, acc
  else
    return pfoldl_recur(i - 1, 1, fn, ...)
  end
end


local function pefoldl_recur(i, n, fn, acc, val, ...)
  if (i == 0) then
    return fn(acc, n, val)
  else
    local cont, nacc = fn(acc, n, val)
    if cont then
      return pefoldl_recur((i - 1), (n + 1), fn, nacc, ...)
    else
      return false, acc
    end
  end
end


--- @generic A, V
--- @param fun fun(acc: A, n: integer, val: V): boolean, A
--- @param acc A
--- @param ... V
local function pefoldl(fun, acc, ...)
  local i = select("#", ...)
  if (i == 0) then
    return false, acc
  else
    return pefoldl_recur((i - 1), 1, fun, acc, ...)
  end
end


return {
    foldl = foldl,
    pfoldl = pfoldl,
    efoldl = efoldl,
    pefoldl = pefoldl,

    all = all,
    any = any,

    foldr = foldr,
    foreach = foreach,
}
