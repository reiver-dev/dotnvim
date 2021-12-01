""" Main nvim config
"""

lua <<EOL
    local mods = {}
    do
        local fs_scandir = vim.loop.fs_scandir
        local fs_next = vim.loop.fs_scandir_next
        local sep = vim.fn.has("win32") == 1 and "\\" or "/"
        local function scandir(prefix, path)
            local fd, _err = fs_scandir(path)
            if fd == nil then error(err) end
            while true do
                local name, fstype = fs_next(fd)
                if name == nil then
                    break
                elseif fstype == "directory" then
                    scandir(prefix .. name .. ".", path .. sep .. name)
                elseif name == "init.lua" then
                    if prefix ~= "" and mods[prefix:sub(1, -2)] == nil then
                        mods[prefix:sub(1, -2)] = path .. sep .. "init.lua"
                    end
                elseif name:sub(-4, -1) == ".lua" then
                    mods[prefix .. name:sub(1, -5)] = path .. sep .. name
                end
            end
        end

        scandir("", vim.fn.stdpath("config") .. sep .. "lua")
    end

    local function private_loader(name)
        local mod = mods[name]
        if mod then
            local f, err = loadfile(mod)
            if f then return f(name) else error(err) end
        end
    end

    if package.loaders[1] == vim._load_package then
        package.loaders[1] = package.loaders[2]
        package.loaders[2] = vim._load_package
    end

    for modname, _ in pairs(mods) do
        package.preload[modname] = private_loader
    end

    local mod = require("bootstrap")
    mod.setup()
    mod.setup_after()
EOL


""" init.vim ends here
