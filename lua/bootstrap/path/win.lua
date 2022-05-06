--- Windows path string manipulation


local sbyte = string.byte


--- @param v integer
--- @return boolean
local function issep(v)
    return v == 47 or v == 92
end


--- @param v integer
--- @return boolean
local function notsep(v)
    return v ~= 47 and v ~= 92
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


local function is_driveletter(letter)
    return (65 <= letter and letter <= 90) or (97 <= letter and letter <= 122)
end


local function plain_unc(s)
    local b, e = string.find(s, "^[\\/][\\/][^\\/]+[\\/][^\\/]+[\\/]*")
    if not b then
        return 0
    end
    return e + 1
end


local function splitroot_pos(s)
    local v1, v2, v3, v4 = string.byte(s, 1, 4)
    if v1 == nil then
        return 0
    end
    -- A:
    if is_driveletter(v1) and v2 == 58 then
        return left_trim(s, issep, 2, #s)
    elseif notsep(v1) then
        -- Relative path
        return 0
    elseif issep(v1) and issep(v2) then
        -- //
        if (v3 == 63 or v3 == 46) and issep(v4) then
            -- //./ or //?/
            return left_trim(s, issep, 4, #s)
        elseif notsep(v3) then
            -- //host/share
            return plain_unc(s)
        end
        return 0
    elseif v1 == 92 and v2 == 63 and v3 == 63 and v4 == 92 then
        -- \??\
        return 5
    else
        return 0
    end
end


local function ensure_cwd(path)
    local a, b = sbyte(path, 1, 2)
    if a == 46 and issep(b) then
        return path
    elseif issep(a) then
        return "." .. path
    else
        return "./" .. path
    end
end


local function splitpath_pos(path)
    local rootpos = splitroot_pos(path)
    local len = #path
    local pos = right_trim(path, issep, rootpos, len)
    return right_trim(path, notsep, rootpos, pos)
end


local function splitroot(path)
    local sub = string.sub
    local rootpos = splitroot_pos(path)
    if rootpos == 0 then
        return "", path
    end
    return sub(path, 1, rootpos - 1), sub(path, rootpos)
end


local function splitpath(path)
    local pos = splitpath_pos(path)
    return string.sub(path, 1, pos), string.sub(path, pos + 1)
end


local function parent(path)
    local pos = splitpath_pos(path)
    return string.sub(path, 1, pos)
end


local function stem(path)
    local pos = splitpath_pos(path)
    return string.sub(path, pos + 1)
end


local function namefile(path)
    local result = path:gsub("[\\/]*$", "")
    return result
end


local function namedir(path)
    if notsep(path:byte(-1)) then
        return path .. "/"
    end
    return path
end


local function split(s)
    local parts = {}
    local i = 1
    local pos = 1
    local len = #s
    local sub = string.sub

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


local function normalize(path, shellshash)
    local slash = string.match(path, "[\\/]")
    if not slash then
        return path
    end
    if shellshash then
        slash = "/"
    end
    local root, tail = splitroot(path)
    if root == "\\??\\" or root == "\\\\?\\" then
        return path
    end
    local parts = split(tail)
    local normparts = { namefile(root):gsub("[\\/]", slash) }
    local n = 2
    for i = 1, #parts do
        local part = parts[i]
        if part == ".." then
            if n == 2 then
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
    return table.concat(normparts, slash)
end


local sub = string.sub


local function iter_parents(state, idx)
    if state[2] < idx then
        local path = state[1]
        local b = state[2]
        local e = idx
        e = right_trim(path, issep, b, e)
        e = right_trim(path, notsep, b, e)
        e = right_trim(path, issep, b, e)
        return e, sub(path, 1, e)
    end
    return nil
end


local function iter_parent_dirs(state, idx)
    if state[2] < idx then
        local p = right_trim(state[1], issep, state[2], idx)
        p = right_trim(state[1], notsep, state[2], p)
        return p, sub(state[1], 1, p)
    end
    return nil
end


local function parents(path, opts)
    local len = #path
    local rootpos = splitroot_pos(path)

    if rootpos > 0 then
        if issep(sbyte(path, rootpos)) then
            rootpos = rootpos + 2
        end
        if opts.exclude_root then
            rootpos = left_trim(path, notsep, rootpos, len)
        end
    elseif opts.exclude_root then
        rootpos = left_trim(path, issep, rootpos + 1, len)
        rootpos = left_trim(path, notsep, rootpos, len)
        if opts.keep_separator then
            rootpos = left_trim(path, issep, rootpos, len)
        end
    else
        path = ensure_cwd(path)
        if opts.keep_separator then
            rootpos = 3
        else
            rootpos = 2
        end
    end

    local iterator

    if opts.keep_separator then
        iterator = iter_parent_dirs
    else
        iterator = iter_parents
    end

    return iterator, { path, rootpos }, len
end


return {
    separator = "\\",
    issep = issep,
    splitroot = splitroot,
    splitpath = splitpath,
    iter_parents = parents,
    parent = parent,
    stem = stem,
    normalize = normalize,
    split = split,
}

--- win.lua ends here
