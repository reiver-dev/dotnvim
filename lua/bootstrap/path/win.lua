--- Windows path string manipulation


local function rcut(path, stop)
    local i = stop or #path
    local at = string.byte

    while 0 < i and (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end

    while 0 < i and not (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end

    return i
end


local function rtrim(path, stop)
    local i = stop or #path
    local at = string.byte
    while 0 < i and (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end
    return i
end


local function ftrim(path, start)
    local i = start or 1
    local e = #path
    local at = string.byte
    while i <= e and (at(path, i) == 47 or at(path, i) == 92) do
        i = i + 1
    end
    return i
end


local function splitpath(path)
    local sub = string.sub
    local match = string.match

    local root = (match(path, "^[a-zA-Z]:[\\/]*") or
                  match(path, "^[\\/][\\/]+[^\\/]+[\\/]+[^\\/]+[\\/]*"))

    local tail_begin
    if root ~= nil then
        tail_begin = #root
    else
        tail_begin = 0
    end

    local tail_end = rcut(path)
    if tail_begin < tail_end then
        return sub(path, 1, tail_end), sub(path, tail_end)
    end

    return root or ".", ""
end

return {
    separator = "\\",
    rcut = rcut,
    rtrim = rtrim,
    ftrim = ftrim,
    splitpath = splitpath,
}

--- win.lua ends here
