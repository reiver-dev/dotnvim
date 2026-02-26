--- Install basic dependencies
--

local modules = require("bootstrap.modules")
local fn = vim.fn

---@type string
local packages = fn.stdpath("data"):gsub("\\", "/") .. "/site/pack/core"

local packer_root = packages .. "/opt/packer.nvim"
local fennel_root = packages .. "/opt/fennel"


---@param name string
---@param source string
---@param dest string
---@return boolean
local function download(source, dest)
    if fn.empty(fn.glob(dest)) > 0 then
        vim.cmd['!']("git", "clone", source, dest)
        return true
    end
    return false
end


---@param path string
local function ensure_rtp(path)
    ---@diagnostic disable-next-line: undefined-field
    vim.opt.runtimepath:append(path)
end


local _pack_event = {}


local function pack_event(spec, ev)
    local data = spec.data

    if data.install then
        if ev == "install" then
            data.install() 
        end
    end

    if data.run then
        if ev == "install" or ev == "update" then
            data.run()
        end
    end

    if data.config then
        data.config()
    end
end


---@param ev any
local function pack_hook(ev)
    print("EV", vim.inspect(ev))
    ---@type vim.pack.PlugData
    local evd = ev.data
    local spec = evd.spec
    if spec.data then
        pack_event(spec, evd.kind)
    else
        _pack_event[spec.name] = evd.kind
    end
end


local function pack_load(pack)
    local spec = pack.spec

    if not spec.data then
        _pack_event[spec.name] = nil
        return
    end

    local ev = _pack_event[spec.name]
    if not ev then
        return
    end

    pack_event(spec, ev)
end


local function pack_add()
    vim.pack.add(
        {
            {
                name = "fennel",
                src = "https://github.com/bakpakin/Fennel",
                data = {
                    run = function()
                        modules.load_package("fennel")
                        require "bootstrap.fennel.ensure_compiler".setup { force = true }
                    end,
                    config = function()
                        modules.eval_after_load("fennel", function()
                            ensure_rtp(fennel_root .. "/rtp")
                        end)
                    end
                },
            },
            {
                name = "packer.nvim",
                src = "https://github.com/wbthomason/packer.nvim",
                data = {
                    install = function()
                        vim.cmd("packadd packer.nvim")
                    end,
                },
            },
        },
        {
            load = pack_load,
            confirm = false,
        }
    )
end


---@param module_name string
---@param parent_loader function
local function load_module(module_name, parent_loader)
    if module_name == nil then
        error("Module name is nil")
    end
    local errors = {}
    local loaders = package.loaders
    for i = 1,#loaders do
        local loader = loaders[i](module_name)
        if vim.is_callable(loader) then
            if loader ~= parent_loader then
                return loader(module_name)
            end
        elseif type(loader) == "string" then
            errors[#errors + 1] = loader
        end
    end
    error(table.concat(errors, "\n"))
end


local function package_preloader(package_name, module_name)
    local function preload_module_loader(modname)
        assert(modname == module_name)
        modules.load_package(package_name)
        return load_module(modname, preload_module_loader)
    end
    return preload_module_loader
end


---@param package_name string
---@param module_name string
local function ensure_plugin_loaders(package_name, module_name)
    package.preload[module_name] = package_preloader(package_name, module_name)
end


local function setup()
    if vim.pack then
        vim.api.nvim_create_autocmd("PackChanged", {
            group = vim.api.nvim_create_augroup("my.pack", {clear = true}),
            pattern = "*",
            callback = pack_hook,
        })
        pack_add()
    else
        if download("https://github.com/wbthomason/packer.nvim", packer_root) then
            vim.cmd("packadd packer.nvim")
        end

        modules.eval_after_load("fennel", function()
            ensure_rtp(fennel_root .. "/rtp")
        end)

        if download("https://github.com/bakpakin/Fennel", fennel_root) then
            vim.cmd("packadd fennel")
            require "bootstrap.fennel.ensure_compiler".setup()
        end
    end

    ensure_plugin_loaders("packer.nvim", "packer")
    ensure_plugin_loaders("fennel", "fennel")
    ensure_plugin_loaders("fennel", "fennel.compiler")
    ensure_plugin_loaders("fennel", "fennel.view")
    ensure_plugin_loaders("fennel", "fennel.metadata")
end


return { setup = setup }

--- setup.lua ends here
