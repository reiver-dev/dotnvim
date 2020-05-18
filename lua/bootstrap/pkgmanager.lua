--- Package management
--

local minpac = require "bootstrap.minpac"
local util = require "bootstrap.util"


local PACKAGES = {}


local function packages()
    return PACKAGES
end


local function package(name)
    return PACKAGES[name]
end


local function call_on_update(package)
    local pkg = PACKAGES[package]
    if pkg ~= nil and pkg.on_update ~= nil then
        local name = pkg.name
        local dir = minpac.getpluginfo(name).dir
        if dir ~= nil then
            return util.with_directory(dir, pkg.on_update)
        end
    end
end


local function hook_on_add(args)
    local hook_type = args[1]
    local package_name = args[2]
    local package = PACKAGES[package_name]
    if package ~= nil then
        local cb = package.on_update
        if cb ~= nil then
            cb()
        end
    end
end


local function schedule_install(url, dir, kind)
    local opts = {
        name = dir,
        type = kind,
        ["do"] = "function('LuaCall', ['bootstrap.pkgmanager', 'hook_on_add'])"
    }
    minpac.add(url, opts)
end


local function load_package(name)
end


local function def(opts)
    local name = opts.name
    local url = opts.url
    local dir = opts.dir
    local kind = opts.kind

    local on_update = opts.on_update

    local init = opts.init    
    local config = opts.config
    local autocmd = opts.autocmd
    local filetype = opts.filetype

    local hooks = opts.hooks or {}

    local pkgdata = {
        name = name,
        pkg = {
            url = url,
            dir = dir,
            kind = kind
        },
        on_update = on_update,
        init = init,
        config = config,
        autocmd = autocmd,
        filetype = filetype,
        hooks = hooks
    }

    PACKAGES[name] = pkgdata

    if url ~= nil then
        schedule_install(url, dir, kind)
    end

    if init ~= nil and (url == nil or minpac.installed(name)) then
        init() 
    end

    return pkgdata
end


local function add(name)
    vim.api.nvim_command("packadd " .. name)
end


local function loaddall()
    vim.api.nvim_command("packloadall")
end


return {
    def = def,
    add = add,
    loadall = loadall,
    packages = packages,
    package = package,
    on_update = call_on_update,

    hook_on_add = hook_on_add,
}


--- pkgmanager.lua ends here
