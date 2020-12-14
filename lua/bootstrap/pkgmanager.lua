--- Package management
--

local packager = require "bootstrap.packager"
local util = require "bootstrap.util"

local M = {}
local PACKAGES = {}


function M.packages()
    return PACKAGES
end


function M.package(name)
    return PACKAGES[name]
end


local function call_on_update(package)
    local pkg = PACKAGES[package]
    if pkg ~= nil and pkg.on_update ~= nil then
        local name = pkg.name
        local dir = packager.plugin(name).dir
        if dir ~= nil then
            return util.with_directory(dir, pkg.on_update)
        end
    end
end


local function call_on_load()
    local pkg = PACKAGES[package]
    if pkg ~= nil and pkg.config ~= nil then
        pkg.config()
    end
end


function maybe_call(func)
    if func ~= nil then
        func()
    end
end


function M._hook_on_add(name)
    local package = PACKAGES[name]
    if package ~= nil then
        local dir = packager.plugin(package.pkg.dir).dir
        if dir ~= nil then
            return util.with_directory(dir, package.on_update)
        end
        maybe_call(package.init)
    end
end


local function is_dir(path)
    local stat = vim.loop.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end


function M.installed(name)
    local info = PACKAGES[name]
    if info ~= nil then
        local info = info.pkg
        local path = ("%s/%s/%s"):format(packager.root(), info.kind, info.dir)
        return is_dir(path)
    end
    return false
end

local FUNCREF = '{... -> v:lua._trampouline("bootstrap.pkgmanager", "_hook_on_add", %q)}'


local function schedule_install(name, url, dir, kind)
    local opts = {
        name = dir,
        type = kind,
    }

    local pkg = PACKAGES[dir]
    if pkg and pkg.on_update then
        local dt = type(pkg.on_update)
        if dt == "string" then
            opts["do"] = pkg.on_update
        elseif dt == "function" then
            opts["do"] = FUNCREF:format(name)
        end
    end

    packager.add(url, opts)
end


local function load_package(name)
end


function M.def(opts)
    local name = opts.name
    local url = opts.url
    local dir = opts.dir or opts.name
    local kind = opts.opt and "opt" or "start"

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

    if init ~= nil and (url == nil or M.installed(name)) then
        init() 
    end

    return pkgdata
end


function M.add(name)
    vim.api.nvim_command("packadd " .. name)
end


function M.loaddall()
    vim.api.nvim_command("packloadall")
end


local function schedule()
    for name, info in pairs(PACKAGES) do
        schedule_install(info.name, info.pkg.url, info.pkg.dir, info.pkg.kind)
    end
end


function M.plugin_update(opt)
    packager.setup()
    schedule()
    local force = 0
    if opt and opt.bang == "!" then
        force = 1
    end
    return packager.updateall({ force_hooks = force })
end


function M.plugin_status()
    packager.setup()
    schedule()
    return packager.status()
end


function M.plugin_clean()
    packager.setup()
    schedule()
    return packager.clean()
end


function M.plugin_install()
    packager.setup()
    schedule()
    packager.install()
end


return M 


--- pkgmanager.lua ends here
