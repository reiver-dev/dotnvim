local root = vim.fn.stdpath("config")
local name = "after.lua"
local path = root .. package.config:sub(1, 1) .. name
local after_source

do
    local fd, err, errno = io.open(path, 'r')

    if fd == nil then
        if errno == 2 then
            local fd = io.open(path, "w")
            if fd then
                local t = "--- After config\n\n--- after.lua ends here\n"
                pcall(fd.write, fd, t)
                fd:close()
            end
        else
            vim.notify(err:gsub("\t", "    "), vim.log.levels.ERROR)
        end
        return
    end

    local ok, text = pcall(fd.read, fd, "*all")
    fd:close()

    if ok ~= true then
        return
    end

    after_source = text
end

local mod, err = loadstring(after_source, "@" .. path)
if mod == nil then
    vim.notify(err:gsub("\t", "    "), vim.log.levels.ERROR)
    return
end

local res = mod()

if type(res) == "function" then
    res()
elseif type(res) == "table" then
    if vim.is_callable(res) then
        res()
    elseif vim.is_callable(res.setup) then
        res.setup()
    end
end
