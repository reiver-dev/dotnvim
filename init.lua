local OS = vim.loop.os_uname()
local iswin = OS.sysname:match("^Windows")
local sep = iswin and "\\" or "/"

do
    local disable = {
        'gzip',
        'zip',
        'zipPlugin',
        'tar',
        'tarPlugin',
        'getscript',
        'getscriptPlugin',
        'vimball',
        'vimballPlugin',
        '2html_plugin',
        'matchit',
        'matchparen',
        'logiPat',
        'rrhelper',
        'netrw',
        'netrwPlugin',
        'netrwSettings',
    }
    local setg = vim.api.nvim_set_var
    for _, name in ipairs(disable) do
        setg('loaded_' .. name, 1)
    end
end

do
    local disable = {
        "python",
        "python3",
        "ruby",
        "node",
        "perl",
    }
    local setg = vim.api.nvim_set_var
    for _, name in ipairs(disable) do
        setg('loaded_' .. name .. '_provider', 0)
    end
end

if iswin then
    pcall(function()
        os.setlocale(".utf8", "all")
        os.setlocale("C", "numeric")
    end)
end

local function get_stdpath()
    local s = {}
    local paths = {'cache', 'config', 'data', 'log', 'run', 'state'}
    local call = vim.call
    for _, path in ipairs(paths) do
        local ok, res = pcall(call, 'stdpath', path)
        if ok then
            s[path] = res
        end
    end
    return setmetatable(s, {
        __index = function(_, k) 
            error("No such stdpath: " .. tostring(k))
        end,
        __newindex = function(_, _, _)
            error("STDPATH is immutable")
        end
    })
end


_G.STDPATH_RAW = get_stdpath()


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


if iswin then
    vim.o.shellslash = true
    require "normalize_shellslash".setup()
    _G.STDPATH = get_stdpath()
else
    _G.STDPATH = _G.STDPATH_RAW
end


require("bufreg").setup()
require("bootstrap").setup()
