--- Module routines
--

local function loaded_packages()
    local rtp = vim.o.runtimepath
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
    local commands = {}
    for _, name in ipairs(names) do
        if not loaded[name] then
            commands[#commands + 1] = "packadd " .. name
        end
    end
    if #commands > 0 then
        vim.api.nvim_exec(table.concat(commands, "\n"), false)
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
    plugins = _G.packer_plugins
    if plugins and next(plugins) then
        local plugin = plugins[name]
        if plugin then
            return plugin.loaded or load_packer_packages({name}, plugins)
        end
    end
    vim.cmd("packadd " .. name)
end


local function load_many_packages(...)
    plugins = _G.packer_plugins
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


local function complete_package(arg, line, pos)
    local plugins = _G.packer_plugins
    local loadable = {}
    if plugins then
        for name, plugin in pairs(plugins) do
            if not plugin.loaded then
                loadable[#loadable + 1] = name
            end
        end
    end
    table.sort(loadable)
    return table.concat(loadable, "\n")
end


local COMMAND = [[
command! -nargs=+ -complete=custom,v:lua.__complete_package LoadPackage lua LOAD_PACKAGE(<f-args>)
]]


local function setup()
    _G.LOAD_PACKAGE = load_package
    _G.__complete_package = complete_package
    vim.api.nvim_exec(COMMAND, false)
end


return { 
    setup = setup,
    load_package = load_package,
    complete_package = complete_packages
}

--- modules.lua ends here
