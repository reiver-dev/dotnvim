local fs_scandir = vim.loop.fs_scandir
local fs_next = vim.loop.fs_scandir_next


local function iter_listdir(state, idx)
    local name, fstype, errcode = fs_next(state)
    if name == nil then
        if errcode then
            error(fstype)
        end
        return nil
    end
    return idx + 1, name, fstype
end


local function listdir(path)
    local fd, err = fs_scandir(path)
    if not fd then error(err) end
    return iter_listdir, fd, 0
end


return listdir
