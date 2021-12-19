-- Makedir with parents

local MODULE = ...
local pathmod = require(MODULE:gsub("%.[^.]*$", ""))
local splitpath, is_dir = pathmod.splitpath, pathmod.is_dir
local uv = vim.loop


local function fserror(fname, err)
    return error(string.format("At file `%s`: %s", fname, err), 1)
end

--- @param path string
local function mkdir(path)
    local numstack = 1
    local stack = {path}

    do
        local head, tail = splitpath(path)
        while tail ~= "" do
            numstack = numstack + 1
            stack[numstack] = head
            head, tail = splitpath(head)
        end
    end

    while numstack > 0 do
        local name = stack[numstack]
        local success, err = uv.fs_mkdir(name, 448)
        if success or is_dir(name) then
            stack[numstack] = nil
            numstack = numstack - 1
        else
            error(fserror(name, err))
        end
    end
end


return mkdir
