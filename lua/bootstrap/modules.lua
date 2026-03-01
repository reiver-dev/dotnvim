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

---@param path string
local function source_after(name)
    local pkgs = vim.pack.get({name}, {info = false})
    for _, pkg in ipairs(pkgs) do
        if pkg and pkg.path then
            local loc = pkg.path .. "/after/plugin/**/*.{vim,lua}"
            local after_paths = vim.fn.glob(loc, false, true)
            for _, p in ipairs(after_paths) do
                vim.cmd.source({ p, magic = { file = false } })
            end
        end
    end
end


local before_load_hook = {}
local after_load_hook = {}
local after_any_load_hook = {}


local function is_loaded(name)
    return is_in_rtp(name) ~= nil
end


local function hook_add(hook, name, func)
    if is_loaded(name) then
        func(name)
    end
    local cbs = hook[name]
    if cbs == nil then
        hook[name] = {func}
    else
        cbs[#cbs + 1] = func
    end
end


local function hook_call(hook, name, ...)
    local cbs = hook[name]
    if cbs == nil then
        return
    end
    for _, hook in ipairs(cbs) do
        hook(name, ...)
    end
    hook[name] = nil
end

local function eval_before_load(name, func)
    hook_add(before_load_hook, name, func)
end


local function call_before_load(name, ...)
    hook_call(before_load_hook, name, ...)
end


local function eval_after_load(name, func)
    hook_add(after_load_hook, name, func)
end


local function call_after_load(name, ...)
    hook_call(after_load_hook, name, ...)
end


local function eval_any_load(func)
    after_any_load_hook[#after_any_load_hook + 1] = func
end

local function call_any_load(...)
    for _, cb in ipairs(after_any_load_hook) do
        cb(...)
    end
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


local function load_packages(names)
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
            call_before_load(name)
            vim.cmd(cmddef)
            call_after_load(name)
            call_any_load(name)
            if vim.v.vim_did_enter == 1 then
                source_after(name)
            end
        end
    end
end


local function load_package(...)
    return load_packages({...})
end


local function complete_package(arg)
    local plugins = vim.pack.get(nil, {info = false})
    local loadable_list = {}
    local loadable = {}
    local i = 1

    if plugins then
        for _, plugin in ipairs(plugins) do
            local name = plugin.spec.name
            if not is_loaded(name) then
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
    is_loaded = is_loaded,
    eval_after_load = eval_after_load,
    call_after_load = call_after_load,
    eval_before_load = eval_before_load,
    call_before_load = call_before_load,
    eval_after_any_load = eval_any_load,
    call_after_any_load = call_any_load,
}

--- modules.lua ends here
