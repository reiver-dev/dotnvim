--- Install basic dependencies
--

local load_package = require("bootstrap.modules").load_package
local fn = vim.fn

local packages = fn.stdpath("data"):gsub("\\", "/") .. "/site/pack/packer"

local packer_root = packages .. "/opt/packer.nvim"
local fennel_root = packages .. "/opt/fennel"


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


local function ensure_plugin_loaders(package_name, module_name)
    package.preload[module_name] = package_preloader(package_name, module_name)
end


local function setup()
    if download("https://github.com/wbthomason/packer.nvim", packer_root) then
        vim.cmd("packadd packer.nvim")
    end

    if download("https://github.com/bakpakin/Fennel", fennel_root) then
        vim.cmd("packadd fennel")
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
