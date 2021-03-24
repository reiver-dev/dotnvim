--- Install basic dependencies
--


local M = {}


local fn = vim.fn

local packages
if fn.has("win32") == 1 then
    packages = fn.stdpath("config"):gsub("\\", "/") .. "/pack/packer"
else
    packages = fn.stdpath("data"):gsub("\\", "/") .. "/site/pack/packer"
end

local packer_root = packages .. "/opt/packer.nvim"
local fennel_root = packages .. "/opt/fennel"
local conjure_root = packages .. "/opt/conjure"


local function make_args(executable, ...)
    local args = {"!", executable, ...}
    for idx = 2,#args,1 do
        args[idx] = fn.shellescape(args[idx]) 
    end
    return table.concat(args, " ")
end


local function download(source, dest)
    if fn.empty(fn.glob(dest)) > 0 then
        vim.cmd(make_args("git", "clone", source, dest))
        return true
    end
    return false
end


local function load_module(module_name)
    if module_name == nil then
         error("Module name is nil")
    end
    local errors = {}
    local loaders = package.loaders
    for i = 1,#loaders do
        local loader = loaders[i](module_name)
        if vim.is_callable(loader) then
            return loader()
        end
        if type(loader) == "string" then
            errors[#errors + 1] = loader
        end
    end
    error(table.concat(errors, "\n"))
end


local function load_package(package_name)
    local packer_plugins = _G.packer_plugins
    if packer_plugins then
        local plugin = packer_plugins[package_name]
        if plugin then
            if not plugin.loaded then
                require("packer.load")({package_name}, {}, packer_plugins)
            end
            return
        end
    end
    vim.cmd("packadd " .. package_name)
end


local function package_preloader(package_name)
    return function(module_name) 
        load_package(package_name)
        return load_module(module_name)
    end
end


local function ensure_plugin_loaders(package_name, module_name)
    package.preload[module_name] = package_preloader(package_name)
end


function M.setup()
    if download("https://github.com/wbthomason/packer.nvim", packer_root) then
        vim.cmd("packadd packer.nvim")
    end

    if download("https://github.com/bakpakin/Fennel", fennel_root) then
        vim.cmd("packadd fennel")
        require "bootstrap.fennel.ensure_compiler".setup()
    end

    download("https://github.com/Olical/conjure", conjure_root)
    
    ensure_plugin_loaders("packer.nvim", "packer")
    ensure_plugin_loaders("fennel", "fennel")
    ensure_plugin_loaders("fennel", "fennel.view")
    ensure_plugin_loaders("fennel", "fennel.metadata")
end


return M

--- setup.lua ends here
