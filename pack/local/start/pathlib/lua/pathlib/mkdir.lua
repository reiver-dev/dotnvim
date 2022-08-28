-- Makedir with parents

local function fserror(fname, err)
    return error(string.format("At file `%s`: %s", fname, err), 1)
end


--- @param path string
local function mkdir(path, pathmod)
    local numstack = 1
    local stack = { path }
    local splitpath, is_dir = pathmod.splitpath, pathmod.is_dir
    local fs_mkdir = vim.loop.fs_mkdir

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
        local success, err = fs_mkdir(name, 448)
        if success or is_dir(name) then
            stack[numstack] = nil
            numstack = numstack - 1
        else
            error(fserror(name, err))
        end
    end
end


return mkdir
