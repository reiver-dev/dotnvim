--- Install basic dependencies
--

local load_package = require("bootstrap.modules").load_package
local fn = vim.fn

---@type string
local packages = fn.stdpath("data"):gsub("\\", "/") .. "/site/pack/packer"

local packer_root = packages .. "/opt/packer.nvim"
local fennel_root = packages .. "/opt/fennel"


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
        load_package(package_name)
        return load_module(modname, preload_module_loader)
    end
    return preload_module_loader
end


---@param package_name string
---@param module_name string
local function ensure_plugin_loaders(package_name, module_name)
    package.preload[module_name] = package_preloader(package_name, module_name)
end


---@param path string
local function ensure_rtp(path)
    ---@diagnostic disable-next-line: undefined-field
    vim.opt.runtimepath:append(path)
end


local function setup()
    if download("https://github.com/wbthomason/packer.nvim", packer_root) then
        vim.cmd("packadd packer.nvim")
    end

    if download("https://github.com/bakpakin/Fennel", fennel_root) then
        vim.cmd("packadd fennel")
        ensure_rtp(fennel_root .. "/rtp")
        require "bootstrap.fennel.ensure_compiler".setup()
    end

    ensure_plugin_loaders("packer.nvim", "packer")
    ensure_plugin_loaders("fennel", "fennel")
    ensure_plugin_loaders("fennel", "fennel.compiler")
    ensure_plugin_loaders("fennel", "fennel.view")
    ensure_plugin_loaders("fennel", "fennel.metadata")
end


return { setup = setup }

--- setup.lua ends here
