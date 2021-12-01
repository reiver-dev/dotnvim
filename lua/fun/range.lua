local abs = math.abs
local ceil = math.ceil
local floor = math.floor


local function empty()
    -- Nothing --
end


local function range_len_inclusive(start, stop, step)
    if step > 0 and start < stop or step < 0 and stop < start then
        return floor(abs(stop - start) / abs(step))
    else
        return 0
    end
end


local function range_len_exclusive(start, stop, step)
    if step > 0 and start < stop or step < 0 and stop < start then
        return ceil(abs(stop - start) / abs(step))
    else
        return 0
    end
end


local function iter_range_inclusive(state, idx)
    if idx <= state[1] then
        return (idx + 1), (state[3] * idx + state[2])
    else
        return nil
    end
end


local function iter_range_exclusive(state, idx)
    if idx < state[1] then
        return (idx + 1), (state[3] * idx + state[2])
    else
        return nil
    end
end


--- Inclusive number range [start, stop)
--- @param start number
--- @param stop number
--- @param step? number
--- @return fun(state: any, idx: integer): integer, number
--- @return any state
--- @return integer idx
local function range(start, stop, step)
    local step = step or 1
    local len = range_len_inclusive(start, stop, step)
    if 0 < len then
        return iter_range_inclusive, {len, start, step}, 0
    else
        return empty, 0, 0
    end
end


--- Exclusive number range [start, stop)
--- @param start number
--- @param stop number
--- @param step? number
--- @return fun(state: any, idx: integer): integer, number
--- @return any state
--- @return integer idx
local function erange(start, stop, step)
    local step = step or 1
    local len = range_len_exclusive(start, stop, step)
    if 0 < len then
        return iter_range_exclusive, {len, start, step}, 0
    end
    return empty, 0, 0
end


local function dup(x)
    return x, x
end


local function irange_iter_inc1(state, idx)
    if idx < state then
        return dup(idx + 1)
    end
end


local function irange_iter_inc(state, idx)
    local nidx = idx + state[2]
    if nidx <= state[1] then
        return dup(nidx)
    end
end


local function irange_iter_dec1(state, idx)
    if (idx > state) then
        return dup(idx - 1)
    end
end


local function irange_iter_dec(state, idx)
    local nidx = (idx - state[2])
    if (nidx >= state[1]) then
        return dup(nidx)
    end
end


--- Integer inclusive range [start, stop]
--- @param start integer
--- @param stop? integer
--- @param step? integer
--- @return fun(state: any, idx: integer): integer, integer
--- @return any state
--- @return integer idx
local function irange(start, stop, step)
    if step == nil then
        if stop == nil then
            return irange_iter_inc1, start, 0
        end
        return irange_iter_inc1, stop, start - 1
    end

    if step == 1 then
        return irange_iter_inc1, stop, start - 1
    elseif step == -1 then
        return irange_iter_dec1, stop, start + 1
    elseif step > 0 then
        return irange_iter_inc, {stop, step}, (start - step)
    elseif step < 0 then
        return irange_iter_dec, {stop, -step}, (start - step)
    end

    return empty, 0, 0
end


return {range = range, erange = erange, irange = irange}
