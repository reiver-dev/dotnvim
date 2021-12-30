--- Iterator adapters and terminals

local function empty() end

--#region Map

local function nested_iter_map(state, idx, ...)
  if (nil ~= idx) then
    return idx, state[1](...)
  else
    return nil
  end
end


local function iter_map_kv_1(state, idx, ...)
  if (nil ~= idx) then
    return idx, state[1](idx, ...)
  else
    return nil
  end
end


local function iter_map(state, idx)
  return nested_iter_map(state, state[2](state[3], idx))
end


local function iter_map_kv(state, idx)
  return iter_map_kv_1(state, state[2](state[3], idx))
end

--- @generic STATE, IDX, A, B, NS
--- @param mapper fun(val: A): B
--- @param iter fun(state: STATE, idx: IDX): IDX, A
--- @param state STATE
--- @param idx IDX
--- @return fun(state: NS, idx: IDX): IDX, B
local function map(mapper, iter, state, idx)
  return iter_map, {mapper, iter, state}, idx
end


local function map_kv(mapper, iter, state, idx)
  return iter_map_kv, {mapper, iter, state}, idx
end

--#endregion

--#region Find

local function nested_find(predicate, iter, state, idx, ...)
  if (nil ~= idx) then
    if predicate(...) then
      return ...
    else
      return nested_find(predicate, iter, state, iter(state, idx))
    end
  else
    return nil
  end
end


local function nested_find_kv(predicate, iter, state, idx, ...)
  if (nil ~= idx) then
    if predicate(idx, ...) then
      return ...
    else
      return nested_find(predicate, iter, state, iter(state, idx))
    end
  else
    return nil
  end
end


local function find(predicate, iter, state, idx)
  return nested_find(predicate, iter, state, iter(state, idx))
end


local function find_kv(predicate, iter, state, idx)
  return nested_find_kv(predicate, iter, state, iter(state, idx))
end

--#endregion

--#region Reduce

local function fold_call(fn, acc, idx, ...)
    if idx ~= nil then
        acc = fn(acc, ...)
    end
    return idx, acc
end


--- @generic A, V, S, I
--- @param fn fun(acc: A, ...: V)
--- @param acc A
--- @param iter fun(state: S, idx: I): V
--- @param idx I
--- @return A
local function fold(fn, acc, iter, state, idx)
    repeat
        idx, acc = fold_call(fn, acc, iter(state, idx))
    until nil == idx
    return acc
end


--- @generic V, S, I
--- @param fn fun(acc: V, ...: V)
--- @param iter fun(state: S, idx: I): V
--- @param idx I
--- @return V
local function reduce(fn, iter, state, idx)
    local acc
    idx, acc = iter(state, idx)
    while idx ~= nil do
        idx, acc = fold_call(fn, acc, iter(state, idx))
    end
    return acc
end

--- @generic S, I
--- @param iter fun(state: S, idx: I): I, ...
--- @param state S
--- @param idx I
--- @return integer
local function count(iter, state, idx)
    local i = 0
    local idx = iter(state, idx)
    while idx ~= nil do
        idx = iter(state, idx)
        i = i + 1
    end
    return i
end


local function apply_next(fn, idx, ...)
    if idx ~= nil then
        fn(...)
        return idx
    end
end


local function apply_next_kv(fn, idx, ...)
    if idx ~= nil then
        fn(idx, ...)
        return idx
    end
end

--- @generic V, S, I
--- @param fn fun(val: V)
--- @param iter fun(state: S, idx: I): V
--- @param idx I
local function each(fn, iter, state, idx)
    repeat
        idx = apply_next(fn, iter(state, idx))
    until idx == nil
end


--- @generic V, S, I
--- @param fn fun(idx: I, val: V)
--- @param iter fun(state: S, idx: I): V
--- @param idx I
local function each_kv(fn, iter, state, idx)
    repeat
        idx = apply_next_kv(fn, iter(state, idx))
    until idx == nil
end

--#endregion

--#region Conditions

local function boolean_call(fn, idx, ...)
    if idx ~= nil then
        local res = fn(...)
        return idx, res
    end
    return nil, false
end


--- @generic V, S, I
--- @param fn fun(val: V): boolean
--- @param iter fun(state: S, idx: I): V
--- @param idx I
--- @return boolean
local function any(fn, iter, state, idx)
    local cond
    repeat
        idx, cond = boolean_call(fn, iter(state, idx))
    until idx == nil and cond
    return cond
end


--- @generic V, S, I
--- @param fn fun(val: V): boolean
--- @param iter fun(state: S, idx: I): V
--- @param idx I
--- @return boolean
local function all(fn, iter, state, idx)
    local cond
    repeat
        idx, cond = boolean_call(fn, iter(state, idx))
    until idx == nil and not cond
    return cond
end

--#endregion

--#region Filter

local function nested_iter_filter(state, idx, ...)
  if (nil ~= idx) then
    if state[1](...) then
      return idx, ...
    else
      return nested_iter_filter(state, state[2](state[3], idx))
    end
  else
    return nil
  end
end


local function iter_filter(state, idx)
  return nested_iter_filter(state, state[2](state[3], idx))
end


local function nested_iter_filter_kv(state, idx, ...)
  if (nil ~= idx) then
    if state[1](idx, ...) then
      return idx, ...
    else
      return nested_iter_filter_kv(state, state[2](state[3], idx))
    end
  else
    return nil
  end
end


local function iter_filter_kv(state, idx)
  return nested_iter_filter_kv(state, state[2](state[3], idx))
end


local function iter_filter1(state, idx)
  local idx0, val = state[2](state[3], idx)
  while ((nil ~= idx0) and not state[1](val)) do
    idx0, val = state[2](state[3], idx0)
  end
  return idx0, val
end


local function iter_filter1_kv(state, idx)
  local idx0, val = state[2](state[3], idx)
  while ((nil ~= idx0) and not state[1](idx0, val)) do
    idx0, val = state[2](state[3], idx0)
  end
  return idx0, val
end


local function filter(predicate, iter, state, idx)
  return iter_filter, {predicate, iter, state}, idx
end


local function filter_kv(predicate, iter, state, idx)
  return iter_filter_kv, {predicate, iter, state}, idx
end


local function filter1(predicate, iter, state, idx)
  return iter_filter1, {predicate, iter, state}, idx
end


local function filter1_kv(predicate, iter, state, idx)
  return iter_filter1_kv, {predicate, iter, state}, idx
end


local function nested_iter_reject(state, idx, ...)
  if (nil ~= idx) then
    if state[1](...) then
      return nested_iter_reject(state, state[2](state[3], idx))
    else
      return idx, ...
    end
  else
    return nil
  end
end


local function iter_reject(state, idx)
  return nested_iter_reject(state, state[2](state[3], idx))
end


local function nested_iter_reject_kv(state, idx, ...)
  if (nil ~= idx) then
    if state[1](idx, ...) then
      return nested_iter_reject_kv(state, state[2](state[3], idx))
    else
      return idx, ...
    end
  else
    return nil
  end
end


local function iter_reject_kv(state, idx)
  return nested_iter_reject_kv(state, state[2](state[3], idx))
end


local function iter_reject1(state, idx)
  local idx0, val = state[2](state[3], idx)
  while ((nil ~= idx0) and state[1](val)) do
    idx0, val = state[2](state[3], idx0)
  end
  return idx0, val
end


local function iter_reject1_kv(state, idx)
  local idx0, val = state[2](state[3], idx)
  while ((nil ~= idx0) and state[1](idx0, val)) do
    idx0, val = state[2](state[3], idx0)
  end
  return idx0, val
end


local function reject(predicate, iter, state, idx)
  return iter_reject, {predicate, iter, state}, idx
end


local function reject_kv(predicate, iter, state, idx)
  return iter_reject_kv, {predicate, iter, state}, idx
end


local function reject1(predicate, iter, state, idx)
  return iter_reject1, {predicate, iter, state}, idx
end


local function reject1_kv(predicate, iter, state, idx)
  return iter_reject1_kv, {predicate, iter, state}, idx
end

--#endregion

--#region Take


local function nested_iter_take(num_remaining, idx, ...)
  if (nil ~= idx) then
    return {(num_remaining - 1), idx}, ...
  else
    return nil
  end
end


local function iter_take(state, idx)
  if (0 ~= idx[1]) then
    return nested_iter_take(idx[1], state[1](state[2], idx[2]))
  else
    return nil
  end
end


local function take(n, iter, state, idx)
  if (0 < n) then
    return iter_take, {iter, state}, {n, idx}
  else
    return empty, nil, nil
  end
end


local function nested_iter_take_one(idx, ...)
  if (idx ~= nil) then
    return {false, idx}, ...
  else
    return nil
  end
end


local function iter_take_one(state, idx)
  if idx[1] then
    return nested_iter_take_one(state[1](state[2], idx[2]))
  else
    return nil
  end
end


local function take_one(iter, state, idx)
  return iter_take_one, {iter, state}, {true, idx}
end


local function nested_iter_take_while(state, idx, ...)
  if ((nil ~= idx) and state[1](...)) then
    return idx, ...
  else
    return nil
  end
end


local function iter_take_while(state, idx)
  return nested_iter_take_while(state, state[2](state[3], idx))
end


local function nested_iter_take_while_kv(state, idx, ...)
  if ((nil ~= idx) and state[1](idx, ...)) then
    return idx, ...
  else
    return nil
  end
end


local function iter_take_while_kv(state, idx)
  return nested_iter_take_while_kv(state, state[2](state[3], idx))
end


local function take_while(predicate, iter, state, idx)
  return iter_take_while, {predicate, iter, state}, idx
end


local function take_while_kv(predicate, iter, state, idx)
  return iter_take_while_kv, {predicate, iter, state}, idx
end

--#endregion

--#region Misc

local function iter_unit(state, idx)
    if idx then
        return false, state
    else
        return nil
    end
end


local function unit(value)
    return iter_unit, value, true
end


local function iter_always(state, idx)
    return idx, state
end


local function always(value)
    return iter_always, value, true
end


local function never()
    return empty, nil, nil
end


local function iter_ntimes(state, idx)
  if (0 ~= idx) then
    return (idx - 1), state
  else
    return nil
  end
end


local function ntimes(n, value)
  if (0 < n) then
    return iter_ntimes, value, n
  else
    return empty, nil, nil
  end
end


local _inext = ipairs({})
local _next = pairs({})


local function this_pairs(tbl)
    return _next, tbl, nil
end


local function this_ipairs(tbl)
    return _inext, tbl, nil
end


local function iter_rpairs(state, idx)
    idx = idx - 1
    if idx ~= 0 then
        return idx, state[idx]
    end
    return nil
end


local function rpairs(tbl)
    return iter_rpairs, tbl, #tbl + 1
end


--#endregion


--#region Enumerate

local function nested_iter_enumerate(nidx, idx, ...)
  if (nil ~= idx) then
    return {(nidx + 1), idx}, (nidx + 1), ...
  else
    return nil
  end
end


local function iter_enumerate(state, idx)
  return nested_iter_enumerate(idx[1], state[1](state[2], idx[2]))
end


local function enumerate(iter, state, idx)
  return iter_enumerate, {iter, state}, {0, idx}
end

--#endregion

--#region KV

local function nested_iter_kv(idx, ...)
    if (nil ~= idx) then
        return idx, idx, ...
    end
end


local function iter_kv(state, idx)
    return nested_iter_kv(state[1](state[2], idx))
end


local function kv(iter, state, idx)
    return iter_kv, {iter, state}, idx
end

--#endregion

--#region Stateful

local function iter_stateful_nested(idx, ...)
    if select("#", ...) == 0 then
        return nil
    end
    return idx + 1, ...
end


local function iter_stateful(state, idx)
    iter_stateful_nested(idx, state())
end

--- @generic VAL
--- @param iter fun():VAL
--- @return fun(state: function, idx: integer):integer,VAL
--- @return fun():VAL
--- @return integer index
local function stateful(iter)
    return iter_stateful, iter, 0
end

--#endregion

--#region Extract

local function iter_extract(state, idx)
    local nidx, key = state[2](state[3], idx)
    if nidx ~= nil then
        return idx, state[1][key]
    end
end


local function extract(container, iter, state, idx)
    return iter_extract, {container, iter, state}, idx
end

--#endregion

--#region Collect

local function _insert(result, i, iter, state, idx)
    local val
    idx, val = iter(state, idx)
    while idx ~= nil do
        result[i] = val
        i = i + 1
        idx, val = iter(state, idx)
    end
    return result
end


local function _append(result, i, iter, state, idx)
    local val
    idx, val = iter(state, idx)
    while idx ~= nil do
        if val ~= nil then
            result[i] = val
            i = i + 1
        end
        idx, val = iter(state, idx)
    end
    return result
end


local function _set_kv(result, iter, state, idx)
    local val
    idx, val = iter(state, idx)
    while idx ~= nil do
        result[idx] = val
        idx, val = iter(state, idx)
    end
    return result
end


local function _set_pairs(result, iter, state, idx)
    local key, val
    idx, key, val = iter(state, idx)
    while idx ~= nil do
        result[key] = val
        idx, key, val = iter(state, idx)
    end
    return result
end


--- @generic V, S, I
--- @param iter fun(state: S, idx: I): I, V
--- @param state S
--- @param idx I
--- @return V[]
--- @nodiscard
local function new_array(iter, state, idx)
    return _insert({}, 1, iter, state, idx)
end


--- @generic V, S, I
--- @param iter fun(state: S, idx: I): I, V
--- @param state S
--- @param idx I
--- @return V[]
--- @nodiscard
local function new_seq(iter, state, idx)
    return _append({}, 1, iter, state, idx)
end


--- @generic K, V, S
--- @param iter fun(state: S, idx?: K): K?, V
--- @param state S
--- @param idx K
--- @return table<K, V>
--- @nodiscard
local function new_kv(iter, state, idx)
    return _set_kv({}, iter, state, idx)
end


--- @generic K, V, S, I
--- @param iter fun(state: S, idx?: I): I, K, V
--- @param state S
--- @param idx I
--- @return table<K, V>
--- @nodiscard
local function new_pairs(iter, state, idx)
    return _set_pairs({}, iter, state, idx)
end


--- @generic V, S, I
--- @param tbl V[]
--- @param i integer
--- @param iter fun(state: S, idx?: I): I, V
--- @param state S
--- @param idx I
--- @return V[]
local function into_array(tbl, i, iter, state, idx)
    if tbl == nil then
        tbl = {}
        i = 1
    elseif i == nil then
        i = #tbl
    end
    return _insert(tbl, i, iter, state, idx)
end


--- @generic V, S, I
--- @param tbl V[]
--- @param i integer
--- @param iter fun(state: S, idx?: I): I, V
--- @param state S
--- @param idx I
--- @return V[]
local function into_seq(tbl, i, iter, state, idx)
    if tbl == nil then
        tbl = {}
        i = 1
    elseif i == nil then
        i = #tbl
    end
    return _append(tbl, i, iter, state, idx)
end


--- @generic K, V, S
--- @param tbl table<K, V>
--- @param iter fun(state: S, idx?: K): K, V
--- @param state S
--- @param idx K
--- @return table<K, V>
local function into_kv(tbl, iter, state, idx)
    if tbl == nil then
        tbl = {}
    end
    return _set_kv(tbl, iter, state, idx)
end


--- @generic K, V, S, I
--- @param tbl table<K, V>
--- @param iter fun(state: S, idx?: I): I, K, V
--- @param state S
--- @param idx I
--- @return table<K, V>
local function into_pairs(tbl, iter, state, idx)
    return _set_pairs(tbl, iter, state, idx)
end


--#endregion

--#region Chain

local iter_chain_1
local iter_chain_2 = function(state, state_pos, idx)
  return iter_chain_1(state, state_pos, state[state_pos * 3 - 2](state[state_pos * 3 - 1], idx))
end

iter_chain_1 = function (state, state_pos, nidx, ...)
  if (nidx == nil) then
    if (nil ~= state[state_pos * 3 + 1]) then
      return iter_chain_2(state, (state_pos + 1), state[(state_pos + 1) * 3])
    else
      return nil
    end
  else
    return {state_pos, nidx}, ...
  end
end

local function iter_chain(state, idx)
  return iter_chain_1(state, idx[1], state[idx[1] * 3 - 2](state[idx[1] * 3 - 1], idx[2]))
end


local function chain_state_prepare(state, num_iterators, i, iterator, ...)
  if (i > num_iterators) then
    return iter_chain, state, {1, state[3]}
  else
    state[((3 * i) - 2)] = iterator[1]
    state[((3 * i) - 1)] = iterator[2]
    state[((3 * i) - 0)] = iterator[3]
    return chain_state_prepare(state, num_iterators, (i + 1), ...)
  end
end

local function chain(...)
  local i = select("#", ...)
  if (i == 0) then
    return empty, nil, nil
  elseif (i == 1) then
    local it = ...
    return it[1], it[2], it[3]
  else
    return chain_state_prepare({}, i, 1, ...)
  end
end

--#endregion


--#region Flatten


local iter_flatmap_next_val


local function iter_flatmap_next_state(state, idx, ...)
    if idx == nil then
        return nil
    end
    local niter, nstate, nidx = state[1](...)
    return iter_flatmap_next_val(state, idx, niter, nstate, niter(nstate, nidx))
end


iter_flatmap_next_val = function(state, state_idx, niter, nstate, idx, ...)
    if idx == nil then
        return iter_flatmap_next_state(state, state[2](state[3], state_idx))
    end
    return {state_idx, niter, nstate, idx}, ...
end


local function iter_flatmap(state, idx)
    return iter_flatmap_next_val(state, idx[1], idx[2], idx[3], idx[2](idx[3], idx[4]))
end


local function flatmap_init(fn, iter, state, idx, ...)
    if idx == nil then return empty end
    local niter, nstate, nidx = fn(...)
    return iter_flatmap, {fn, iter, state}, {idx, niter, nstate, nidx}
end


local function flatmap(fn, iter, state, idx)
    return flatmap_init(fn, iter, state, iter(state, idx))
end


--#endregion

--#region Zip

local function nested_iter_zip(i, state_pos, nidx, pidx, state, ...)
  if (0 ~= i) then
    local idx, value = state[state_pos](state[state_pos + 1], pidx[i])
    if (nil ~= idx) then
      nidx[i] = idx
      return nested_iter_zip(i - 1, state_pos - 2, nidx, pidx, state, value, ...)
    else
      return nil
    end
  else
    return nidx, ...
  end
end

local function iter_zip(state, idx)
  return nested_iter_zip(state[1], state[2], {}, idx, state)
end


local function zip_prepare(count, nidx, dest_state, dest_idx, iterator, ...)
  if (nidx <= count) then
    if (nil ~= iterator) then
      dest_state[2 + nidx * 2] = iterator[1]
      dest_state[2 + nidx * 2 + 1] = iterator[2]
      dest_idx[nidx] = iterator[3]
      return zip_prepare(count, (nidx + 1), dest_state, dest_idx, ...)
    else
      return error(string.format("Iterator is nil, pos: %d", nidx))
    end
  else
    dest_state[1] = count
    dest_state[2] = (1 + (count * 2))
    return iter_zip, dest_state, (#dest_idx and dest_idx)
  end
end


local function zip(...)
  return zip_prepare(select("#", ...), 1, {0, 0}, {}, ...)
end

--#endregion

return {
    map = map,
    map_kv = map_kv,
    fold = fold,
    reduce = reduce,
    count = count,
    any = any,
    all = all,
    each = each,
    foreach = each,
    each_kv = each_kv,
    foreach_kv = each_kv,
    filter = filter,
    filter1 = filter1,
    filter_kv = filter_kv,
    filter1_kv = filter1_kv,
    reject = reject,
    reject1 = reject1,
    reject_kv = reject_kv,
    reject1_kv = reject1_kv,
    take = take,
    take_one = take_one,
    take_while = take_while,
    take_while_kv = take_while_kv,
    kv = kv,
    pairs = pairs,
    ipairs = ipairs,
    rpairs = rpairs,
    stateful = stateful,
    find = find,
    find_kv = find_kv,
    extract = extract,
    new_array = new_array,
    new_seq = new_seq,
    new_kv = new_kv,
    new_pairs = new_pairs,
    into_array = into_array,
    into_seq = into_seq,
    into_kv = into_kv,
    into_pairs = into_pairs,
    unit = unit,
    always = always,
    never = never,
    ntimes = ntimes,
    enumerate = enumerate,
    chain = chain,
    flatmap = flatmap,
    zip = zip,
}
