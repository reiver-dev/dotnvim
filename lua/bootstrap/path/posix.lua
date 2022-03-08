--- Posix path string manipulation

local sbyte = string.byte
local sub = string.sub


local function issep(v)
    return v == 47
end


local function notsep(v)
    return v ~= 47
end


local function left_trim(s, pred, left, right)
    local at = sbyte
    while left <= right and pred(at(s, left)) do
        left = left + 1
    end
    return left
end


local function right_trim(s, pred, left, right)
    local at = sbyte
    while left <= right and pred(at(s, right)) do
        right = right - 1
    end
    return right
end


local function splitroot(path)
    local len = #path
    local pos = left_trim(path, issep, 1, len)
    return sub(path, 1, pos - 1), sub(path, pos, len)
end


local function splitpath_pos(path, len)
    local i = left_trim(path, issep, 1, len)
    return right_trim(path, notsep, i, right_trim(path, issep, i, len))
end


local function splitpath(path)
    local len = #path
    local pos = splitpath_pos(path, len)
    return sub(path, 1, pos - 1), sub(path, pos, len)
end


local function parent(path)
    local pos = splitpath_pos(path, #path)
    return sub(path, 1, pos - 1)
end


local function stem(path)
    local len = #path
    local pos = splitpath_pos(path, len)
    return sub(path, pos, len)
end


local function split(s)
    local parts = {}
    local i = 1
    local pos = 1
    local len = #s
    local sub = sub

    while pos <= len do
        local start = left_trim(s, issep, pos, len)
        local finish = left_trim(s, notsep, start, len)
        if start < finish then
            parts[i] = sub(s, start, finish - 1)
            i = i + 1
        end
        pos = finish
    end

    return parts
end


local function boolnum(v)
    return v and 1 or 0
end


local function normalize(path)
    if path == "" then
        return ""
    end

    local v1, v2, v3 = sbyte(path, 1, 3)
    local n = boolnum(issep(v1)) + boolnum(issep(v2)) + boolnum(issep(v3))

    local normparts
    if n == 0 then
        normparts = {}
    elseif n == 1 then
        normparts = {""}
    elseif n == 2 then
        normparts = {"", ""}
    elseif n == 3 then
        normparts = {""}
    end

    local b = #normparts + 1
    local n = b

    local len = #path
    local pos = 1

    while pos <= len do
        local start = left_trim(path, issep, pos, len)
        local finish = left_trim(path, notsep, start, len)
        if start < finish then
            local part = sub(path, start, finish - 1)
            if part == ".." then
                if n == b then
                    normparts[n] = part
                    n = n + 1
                else
                    normparts[n] = nil
                    n = n - 1
                end
            elseif part ~= "." then
                normparts[n] = part
                n = n + 1
            end
        end
        pos = finish
    end

    return table.concat(normparts, "/")
end


local function namefile(path)
    local result = left_trim(path, issep, 1, #path)
    return result
end


local function namedir(path)
    if notsep(path:byte(-1)) then
        return path .. "/"
    end
    return path
end


local function iter_parent_dirs(state, idx)
    if state[2] < idx then
        local path = state[1]
        local b = state[2]
        idx = right_trim(path, notsep, b, right_trim(path, issep, b, idx))
        return idx, sub(path, 1, idx)
    end
end


local function iter_parents(state, idx)
    if state[2] < idx then
        local path = state[1]
        local b = state[2]
        idx = right_trim(path, issep, b,
                         right_trim(path, notsep, b,
                                    right_trim(path, issep, b, idx)))
        return idx, sub(path, 1, idx)
    end
end


local function parents(path, opts)
    local len = #path
    local rootpos = left_trim(path, issep, 1, len)
    --- Relative
    if notsep(sbyte(path, 1)) then
        rootpos = left_trim(path, notsep, rootpos, len)
        if opts.exclude_root then
            rootpos = left_trim(path, issep, rootpos, len)
            rootpos = left_trim(path, notsep, rootpos, len)
        end
    -- Absolute
    elseif opts.exclude_root then
        rootpos = left_trim(path, notsep, rootpos, len)
    end

    local iterator
    if opts.keep_separator then
        iterator = iter_parent_dirs
        rootpos = left_trim(path, issep, rootpos, len)
    else
        iterator = iter_parents
    end
    return iterator, {path, rootpos}, len
end


return {
    separator = "/",
    issep = issep,
    splitroot = splitroot,
    splitpath = splitpath,
    iter_parents = parents,
    parent = parent,
    stem = stem,
    normalize = normalize,
    split = split,
}


--- posix.lua ends here
