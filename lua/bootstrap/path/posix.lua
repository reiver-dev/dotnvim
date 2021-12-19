--- Posix path string manipulation


local function rcut(path, stop)
    local i = stop or #path
    local at = string.byte

    while 0 < i and at(path, i) == 47 do
        i = i - 1
    end

    while 0 < i and at(path, i) ~= 47 do
        i = i - 1
    end

    return i
end


local function rtrim(path, stop)
    local i = stop or #path
    local at = string.byte
    while 0 < i and at(path, i) == 47 do
        i = i - 1
    end
    return i
end


local function ftrim(path, start)
    local i = start or 1
    local e = #path
    local at = string.byte
    while i < e and at(path, i) == 47 do
        i = i + 1
    end
    return i
end


local function splitpath(path)
    local sub = string.sub
    local i = ftrim(path)
    local pos = rcut(path)
    if pos > i then
        return sub(path, 1, pos), sub(path, pos)
    end
    if i == 2 then
        return "//", ""
    elseif i > 0 then
        return "/", ""
    else
        return ".", ""
    end
end


return {
    separator = "/",
    rcut = rcut,
    rtrim = rtrim,
    ftrim = ftrim,
    splitpath = splitpath,
}


--- posix.lua ends here
