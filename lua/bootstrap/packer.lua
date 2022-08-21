-- Packer package manager config

local function packer_config()
    local pj = require "packer.util".join_paths
    return {
        display = {open_cmd = "vertical botright new [packer]"},
        compile_path = pj(vim.fn.stdpath("data"), "packer_compiled.lua"),
        disable_commands = true,
    }
end

local function argpairs_1(tbl, n, k, v, ...)
    if k then
        tbl[k] = v
    end
    if n > 0 then
        argpairs_1(tbl, n - 2, ...)
    else
        return tbl
    end
end


local function argpairs(...)
    argpairs_1({}, select("#", ...) - 2, ...)
end


local function run_after_load_hook(...)
    _G.__after_load_hook(...)
end


local function handle_packer_options(...)
    local options
    if select("#", ...) == 1 then 
        options = ...
    else
        options = argpairs(...)
    end
    options.as = options.name
    options[1] = options.url
    options.name = nil
    options.url = nil
    if options.opt then
        if options.config then
            options.config = {options.config, run_after_load_hook}
        else
            options.config = {run_after_load_hook}
        end
    end
    return options
end


local function make_packer_module(mod)
    if mod == nil then mod = require "packer" end
    local use = mod.use
    return function(...)
        use(handle_packer_options(...)) 
    end
end


local package_hooks = {}


local function package_hook_set(name, hook)
    package_hooks[name] = hook
end


local function package_hook_execute(packer)
    for name, hook in pairs(package_hooks) do
        hook(make_packer_module(packer))
    end
end


local function init_packages()
    local packer = require "packer"
    packer.init(packer_config())
    packer.reset()
    package_hook_execute(packer)
end


local function path_sep()
    local ok, ss = pcall(vim.api.nvim_get_option, "shellslash") 
    if ok and ss == false then
        return "\\" 
    else
        return "/"
    end
end


local function configure_default_packages(...)
    local path = vim.fn.stdpath("config") .. path_sep() .. "pkg.lua"
    local mod, err = assert(loadfile(path))
    if mod == nil then
        vim.notify(err:gsub("\t", "    "), vim.log.levels.ERROR)
        return
    end
    mod(...)
end


local function refresh()
    package_hook_set("init_pkg", configure_default_packages)
    init_packages()
end


local function open_dir(plugin_names, command_mods)
    local packer_plugins = _G.packer_plugins
    for _, name in ipairs(plugin_names) do
        local plugin = packer_plugins[name]
        if plugin then
            vim.cmd(
                (command_mods or "")
                .. " split "
                .. vim.fn.fnameescape(plugin.path)
            )
        end
    end
end


local function setup()
    local plugin_complete = _F("packer", "plugin_complete")
    local make_command = function(name)
        return function(opts)
            refresh()
            return _T("packer", name, unpack(opts.fargs))
        end
    end
    local plugin_command_opts = {
        nargs = "*",
        complete = plugin_complete,
    }
    local none = {}
    command = vim.api.nvim_create_user_command
    command("PackerInit", init_packages, none)
    command("PackerOpen", function(opts)
        open_dir(opts.fargs, opts.mods)
    end, plugin_command_opts)
    command("PackerInstall", make_command("install"), plugin_command_opts)
    command("PackerUpdate", make_command("update"), plugin_command_opts)
    command("PackerSync", make_command("sync"), plugin_command_opts)
    command("PackerClean", make_command("clean"), none)
    command("PackerCompile", function(opts)
        refresh()
        return _T("packer", "compile", opts.args)
    end, {nargs = "*"})
    command("PackerStatus", make_command("status"), none)
    command("PackerProfile", make_command("profile"), none)

    if vim.fn.exists("&shellslash") == 1 then
        vim.api.nvim_create_autocmd("OptionSet", {
            pattern = 'shellslash',
            group = vim.api.nvim_create_augroup("boostrap-packer", { clear = true, }),
            callback = function()
                local pu = package.loaded['packer.util']
                if pu then
                    pu.use_shellslash = vim.o.shellslash
                end
            end
        })
    end
end


return {
    setup = setup,
    hook = package_hook_set,
}
