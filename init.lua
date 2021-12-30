if os.getenv("AK_PROFILER") then
    vim.cmd "packadd profiler"
    require("profiler")
end

local sep = vim.fn.has("win32") == 1 and "\\" or "/"

local mods
do
    local fs_scandir = vim.loop.fs_scandir
    local fs_next = vim.loop.fs_scandir_next

    local function scandir(mods, ext, dirmod, prefix, path)
        local fd, err = fs_scandir(path)
        if fd == nil then error(err) end
        while true do
            local name, fstype = fs_next(fd)
            if name == nil then
                break
            elseif fstype == "directory" then
                scandir(mods, ext, dirmod,
                        prefix .. name .. ".",
                        path .. sep .. name)
            elseif name == dirmod then
                if prefix ~= "" and mods[prefix:sub(1, -2)] == nil then
                    mods[prefix:sub(1, -2)] = path .. sep .. dirmod
                end
            elseif name:sub(-4, -1) == ext then
                mods[prefix .. name:sub(1, -5)] = path .. sep .. name
            end
        end
    end

    -- Remember as global
    function SCAN_MODULES(path)
        local mods = {}
        local ext = ".lua"
        local dirmod = "init.lua"
        scandir(mods, ext, dirmod, "", path)
        return mods
    end

    mods = SCAN_MODULES(vim.fn.stdpath("config") .. sep .. "lua")
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

do
    local path = vim.fn.stdpath("data") .. sep .. "packer_compiled.lua"
    local mod, err = loadfile(path)
    if mod then
        mod()
    elseif not err:match("No such file or directory$") then
        error(err)
    end
end

mod.setup_after()