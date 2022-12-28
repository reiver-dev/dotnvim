--- Module routines
--

local runtimepath
if vim.fn.has("win32") then
    runtimepath = function()
        return vim.api.nvim_get_option("runtimepath"):gsub("\\", "/")
    end
else
    runtimepath = function()
        return vim.api.nvim_get_option("runtimepath")
    end
end


local function is_in_rtp(name)
    local rtp = runtimepath()
    local pname = vim.pesc(name)
    local pattern = "/pack/[^/]+/([^/]+)/" .. pname .. "[,/$]"
    for kind in rtp:gmatch(pattern) do
        return kind
    end
    return nil
end


local after_load_hook = {}


local function is_loaded(name)
    local packer_plugins = _G.packer_plugins
    if packer_plugins then
        local pack = packer_plugins[name]
        if pack then return pack.loaded end
    end
    return is_in_rtp(name) ~= nil
end


local function eval_after_load(name, func)
    if is_loaded(name) then
        func(name)
    end
    local hooks = after_load_hook[name]
    if hooks == nil then
        after_load_hook[name] = {func}
    else
        hooks[#hooks + 1] = func
    end
end


local function call_after_load(name, ...)
    local hooks = after_load_hook[name]
    if hooks == nil then
        return
    end
    for _, hook in ipairs(hooks) do
        hook(name, ...)
    end
    after_load_hook[name] = nil
end


local function loaded_packages()
    local rtp = runtimepath()
    local pattern = "/pack/[^/]+/opt/([^/,]+)"
    local loaded = {}
    for name in rtp:gmatch(pattern) do
        loaded[name] = true
    end
    return loaded
end


local function load_direct_packages(names)
    if not (names and next(names)) then
        return
    end

    local loaded = loaded_packages()

    local non_loaded_names = {}
    for _, name in ipairs(names) do
        if not loaded[name] then
            non_loaded_names[#non_loaded_names + 1] = name
        end
    end

    if #non_loaded_names > 0 then
        local cmddef = { cmd = "packadd", args = { "" } }
        for _, name in ipairs(non_loaded_names) do
            cmddef.args[1] = name
            vim.cmd(cmddef)
            call_after_load(name)
        end
    end
end


local function load_packer_packages(names, plugins)
    require("packer.load")(names, {}, plugins or _G.packer_plugins);
end


local function partition_packages(plugins, ...)
    local managed = {}
    local direct = {}
    for i = 1,select("#", ...) do
        local name = select(i, ...)
        if type(name) == "string" and name ~= "" then
            local plugin = plugins[name]
            if plugin then
                if not plugin.loaded then
                    managed[#managed + 1] = name
                end
            else
                direct[#direct + 1] = name
            end
        end
    end
    return managed, direct
end


local function load_single_package(name)
    local plugins = _G.packer_plugins
    if plugins and next(plugins) then
        local plugin = plugins[name]
        if plugin then
            return plugin.loaded or load_packer_packages({name}, plugins)
        end
    end
    load_direct_packages { name }
end


local function load_many_packages(...)
    local plugins = _G.packer_plugins
    if plugins and next(plugins) then
        local managed, direct = partition_packages(plugins, ...)
        if #direct > 0 then
            load_direct_packages(direct)
        end
        if #managed > 0 then
            load_packer_packages(managed, plugins)
        end
        return
    end
    return load_direct_packages({...})
end


local function load_package(...)
    local n = select("#", ...)
    if n == 0 then
        return
    elseif n == 1 then
        return load_single_package(...)
    else
        return load_many_packages(...)
    end
end


local function complete_package(arg)
    local plugins = _G.packer_plugins
    local loadable_list = {}
    local loadable = {}
    local i = 1

    if plugins then
        for name, plugin in pairs(plugins) do
            if not plugin.loaded then
                loadable_list[i] = name
                loadable[name] = true
                i = i + 1
            end
        end
    end

    do
        local direct = vim.fn.getcompletion("", "packadd", 0)
        local loaded = loaded_packages()
        for _, name in ipairs(direct) do
            if loadable[name] == nil and loaded[name] == nil then
                loadable_list[i] = name
                i = i + 1
            end
        end
    end

    if #arg > 0 then
        local len = #arg
        local sub = string.sub
        loadable_list = vim.tbl_filter(function(name)
            return sub(name, 1, len) == arg
        end, loadable_list)
    end

    return loadable_list
end


local function setup()
    _G.LOAD_PACKAGE = load_package
    _G.EVAL_AFTER_LOAD = eval_after_load
    _G.__after_load_hook = call_after_load
    vim.api.nvim_create_user_command(
        "LoadPackage",
        function(opts) load_package(unpack(opts.fargs)) end,
        {
            desc = "bootstrap.modules::load_package",
            nargs = "+",
            complete = complete_package,
        }
    )
end


return {
    setup = setup,
    load_package = load_package,
    complete_package = complete_package,
    call_after_load = call_after_load,
}

--- modules.lua ends here
