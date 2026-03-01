--- autoload.lua

local modules = require "bootstrap.modules"

local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_exec_autocmds = vim.api.nvim_exec_autocmds
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_del_augroup_by_name = vim.api.nvim_del_augroup_by_name
local nvim_create_user_command = vim.api.nvim_create_user_command
local nvim_del_user_command = vim.api.nvim_del_user_command
local nvim_call_function = vim.api.nvim_call_function
local nvim_set_keymap = vim.api.nvim_set_keymap
local nvim_del_keymap = vim.api.nvim_del_keymap
local nvim_input = vim.api.nvim_input
local nvim_feedkeys = vim.api.nvim_feedkeys
local nvim_cmd = vim.api.nvim_cmd

---@alias KeyMod
---| '"i"'
---| '"n"'

---@class Key
---@field [1] KeyMod
---@field [2] string

---@class my.autoload.Spec
---@field cmd string[]?
---@field event string[]?
---@field keys Key[]?
---@field ft string[]?
---@field module string[]?
---@field after string[]?


local _fields = {
    cmd = true,
    event = true,
    keys = true,
    ft = true,
    module = true,
    after = true,
}


local _pending = {}
local _loaded = {}

local _ft = {}
local _modmap = {}
local _after = {}
local _after_target = {}


local function nest(tbl, key)
    local v = tbl[key]
    if not v then
        v = {}
        tbl[key] = v
    end
    return v
end


local _plain = { plain = true, trimempty = true }
local function modsplit(mod)
    return vim.gsplit(mod, ".", _plain)
end


local function modmap_add(pkgname, mods)
    local modmap = _modmap
    for _, mod in ipairs(mods) do
        local mm = modmap
        for part in modsplit(mod) do
            mm = nest(mm, part)
        end
        local pkgs = nest(mm, true)
        pkgs[pkgname] = true
    end
end


local function modmap_del(pkgname, mods)
    local modmap = _modmap
    for _, mod in ipairs(mods) do
        local mm = modmap
        for part in modsplit(mod) do
            mm = mm[part]
            if not mm then
                break
            end
        end
        if mm then
            local pkgs = mm[true]
            if pkgs then
                pkgs[pkgname] = nil
            end
        end
    end
end


local function modmap_fetch(mod)
    local modmap = _modmap
    local result = {}
    local mm = modmap
    if not mm then
        return result
    end
    local ir = 1
    for part in modsplit(mod) do
        mm = mm[part]
        if not mm then
            break
        end
        local pkgs = mm[true]
        if pkgs then
            mm[true] = nil
            for pkg, _ in pairs(pkgs) do
                result[ir] = pkg
                ir = ir + 1
            end
        end
    end
    return result
end


---@param name string
---@param deps string[]?
local function dependency_add(name, deps)
    if not deps then
        return
    end
    local target = _after_target[name]
    if not target then
        target = {}
        _after_target[name] = target
    end
    local after = _after
    local loaded = _loaded
    for _, dep in ipairs(deps) do
        if not loaded[dep] then
            local a = after[dep]
            if a then
                a[#a + 1] = name
            else
                after[dep] = { name }
            end
            target[dep] = true
        end
    end
end


---@param name string
---@return string[]?
local function dependency_trigger(name)
    local deps = _after[name]
    if not deps then
        return
    end
    _after[name] = nil
    local result
    local i = 0
    local target = _after_target
    for _, dep in ipairs(deps) do
        local t = target[dep]
        if t and t[name] then
            t[name] = nil
            if not next(t) then
                target[dep] = nil
                if i == 0 then
                    i = 1
                    result = { dep }
                else
                    i = i + 1
                    result[i] = dep
                end
            end
        end
    end
    return result
end


---@generic T
---@param arr T[]
---@param val T
local function array_remove(arr, val)
    for i, v in ipairs(arr) do
        if v == val then
            table.remove(arr, i)
            return
        end
    end
end


---@param name string
local function dependency_clear(name)
    local target = _after_target[name]
    if not target then
        return
    end
    local deps = _after
    _after_target[name] = nil
    for t in pairs(target) do
        local d = deps[t]
        if d then
            array_remove(d, name)
        end
    end
end


local function filetype_clear(pkgname, filetypes)
    local ft = _ft
    for _, filetype in ipairs(filetypes) do
        local subset = ft[filetype]
        if subset then
            subset[pkgname] = nil
        end
    end
end


---@param filetype string
---@return string[]?
local function filetype_trigger(filetype)
    local ft = _ft[filetype]
    if not ft then
        return
    end
    local pkgs = {}
    local i = 1
    for pkg, _ in pairs(ft) do
        pkgs[i] = pkg
        i = i + 1
        ft[pkg] = nil
    end
    return pkgs
end


---@param cmdargs vim.api.keyset.create_user_command.command_args
---@return vim.api.keyset.cmd
local function prepare_cmd(cmdargs)
    local count
    local range
    local reg

    if cmdargs.range == 1 then
        count = cmdargs.count
    elseif cmdargs.range == 2 and (cmdargs.line1 or cmdargs.line2) then
        range = { cmdargs.line1, cmdargs.line2 }
    end

    if cmdargs.reg and cmdargs.reg ~= "" then
        reg = cmdargs.reg
    end

    return {
        cmd = cmdargs.name,
        count = count,
        reg = reg,
        bang = cmdargs.bang,
        args = cmdargs.fargs,
        nargs = cmdargs.nargs,
        mods = cmdargs.smods,
        range = range,
    }
end


local function clear_loaders(name, spec)
    if not spec then
        return
    end

    if spec.cmd then
        for _, cmdname in ipairs(spec.cmd) do
            nvim_del_user_command(cmdname)
        end
    end

    if spec.keys then
        for _, mapping in ipairs(spec.keys) do
            local mode = mapping[1]
            local key = mapping[2]
            nvim_del_keymap(mode, key)
        end
    end

    if spec.event then
        nvim_del_augroup_by_name("autoload.hook/" .. name)
    end

    if spec.ft then
        filetype_clear(name, spec.ft)
    end

    if spec.module then
        modmap_del(name, spec.module)
    end

    if spec.after then
        dependency_clear(name)
    end
end



local function pending_extend(name, spec)
    local state = _pending[name]
    if not state then
        state = {}
        _pending[name] = state
    end
    local expected_fields = _fields
    for key, req in pairs(spec) do
        if expected_fields[key] then
            local prop = state[key]
            if not prop then
                prop = {}
                state[key] = prop
            end
            local i = #prop
            for j = 1,#req do
                i = i + 1
                prop[i] = req[j]
            end
        end
    end
end


local function pending_trigger(name)
    local p = _pending[name]
    _pending[name] = nil
    return p
end


---@param pkgname string
local function on_autoload(pkgname)
    local p = pending_trigger(pkgname)
    if p then
        clear_loaders(p)
    end
    modules.load_package(pkgname)
end


local _EMPTY = {}
local function on_command(pkgname, cmdargs)
    on_autoload(pkgname)
    nvim_cmd(prepare_cmd(cmdargs), _EMPTY)
end


local function on_command_complete(pkgname)
    on_autoload(pkgname)
end


local function on_filetype(ev)
    local pkgs = filetype_trigger(ev.file)
    if not pkgs then return end
    for _, pkg in ipairs(pkgs) do
        on_autoload(pkg)
    end
end


local function on_dependency(name)
    local toload = dependency_trigger(name)
    if toload then
        modules.load_package(unpack(toload))
    end
end


local function on_key(pkgname, mode, key)
    on_autoload(pkgname)
    if mode == "n" then
        nvim_input(key)
    else
        nvim_feedkeys(key, '', false)
    end
end

---@param pkgname string
---@param keys my.pack.KeySpec[]
local function schedule_keys(pkgname, keys)
    for _, key in ipairs(keys) do
        local mode = key[1]
        local lhs = key[2]
        if type(mode) == "string" then
            nvim_set_keymap(mode, lhs, "", {
                callback = function()
                    on_key(pkgname, mode, lhs)
                end
            })
            return
        else
            local opts = { callback = false }
            for _, m in ipairs(mode) do
                function opts.callback()
                    on_key(pkgname, m, lhs)
                end

                nvim_set_keymap(mode, lhs, "", opts)
            end
        end
    end
end


local function schedule_commands(pkgname, cmdnames)
    for _, cmdname in ipairs(cmdnames) do
        local function action(cmdargs)
            on_command(pkgname, cmdargs)
        end
        local comparg = nil
        local opts = {
            nargs = "*",
            range = true,
            bang = true,
            complete = function()
                on_command_complete(pkgname)
                if not comparg then
                    comparg = { cmdname .. " ", "cmdline" }
                end
                return nvim_call_function("getcompletion", comparg)
            end,
        }
        nvim_create_user_command(cmdname, action, opts)
    end
end


local function schedule_filetypes(pkgname, filetypes)
    for _, filetype in ipairs(filetypes) do
        local ft = _ft[filetype]
        if ft then
            ft[pkgname] = true
        else
            ft = { pkgname }
            _ft[filetype] = ft
        end
    end
end


---@param pkgname string
---@param events string[]
local function schedule_events(pkgname, events)
    local group = nvim_create_augroup("autoload.hook/" .. pkgname, { clear = true })
    nvim_create_autocmd(events, {
        group = group,
        callback = function(arg)
            on_autoload(pkgname)
            nvim_exec_autocmds(arg.event, {
                pattern = arg.match,
                modeline = false,
            })
        end,
        once = true,
    })
end


---@param pkgname string
---@param mods string[]
local function schedule_modules(pkgname, mods)
    modmap_add(pkgname, mods)
end


---@param pkgname string
---@param depends string[]
local function schedule_after(pkgname, depends)
    dependency_add(pkgname, depends)
end


---@param module_name string
---@param parent_loader function
local function load_module(module_name, parent_loader)
    if module_name == nil then
        error("Module name is nil")
    end
    local errors = {}
    local loaders = package.loaders

    for i = 1, #loaders do
        local loader = loaders[i]
        if loader == parent_loader then
            return
        end

        local mod = loader(module_name)

        if vim.is_callable(mod) then
            return mod(module_name)
        elseif type(loader) == "string" then
            errors[#errors + 1] = loader
        end
    end

    error(table.concat(errors, "\n"))
end

local function loader(modname)
    local pkgs = modmap_fetch(modname)
    if not next(pkgs) then
        return
    end
    for _, pkg in ipairs(pkgs) do
        local ok, err = pcall(on_autoload, pkg)
        if not ok then
            local msg = string.format("Package (%s) module (%s) autoload error: %s", pkg, modname, err)
            vim.notify(msg, vim.log.levels.ERROR)
        end
    end
    return load_module(modname, loader)
end


local function get_loaders()
    local res = {}
    for i, l in ipairs(package.loaders) do
        local info = debug.getinfo(l, "Sn")
        res[i] = info
    end
    return res
end



local function setup()
    local g = nvim_create_augroup("autoload", {})
    table.insert(package.loaders, 2, loader)
    nvim_create_autocmd("FileType", {
        group = g,
        callback = on_filetype,
    })
    modules.eval_after_any_load(function(pkgname)
        _loaded[pkgname] = true
        on_dependency(pkgname)
    end)
end


local function eval_after_load(name, callback)
    modules.eval_after_load(name, callback)
end


---@params name string
---@params opts my.autoload.Spec
local function schedule_autoload(name, opts)
    local scheduled = false
    if opts.cmd then
        schedule_commands(name, opts.cmd)
        scheduled = true
    end

    if opts.keys then
        schedule_keys(name, opts.keys)
        scheduled = true
    end

    if opts.ft then
        schedule_filetypes(name, opts.ft)
        scheduled = true
    end

    if opts.event then
        schedule_events(name, opts.event)
        scheduled = true
    end

    if opts.module then
        schedule_modules(name, opts.module)
        scheduled = true
    end

    if opts.after then
        schedule_after(name, opts.after)
        scheduled = true
    end

    return scheduled
end


local function trigger(name)
    on_autoload(name)
end


local function schedule(name, opts)
    if not name or _loaded[name] or not opts then
        return
    end
    if schedule_autoload(name, opts) then
        pending_extend(name, opts)
    end
end


local function get_depmap()
    return _after_target, _after
end


local function get_modmap()
    return _modmap
end


local function get_loaded()
    return _loaded
end


return {
    schedule = schedule,
    trigger = trigger,
    setup = setup,
    loader = loader,
    eval = eval_after_load,
    debug_loaders = get_loaders,
    modmap = get_modmap,
    depmap = get_depmap,
    loaded = get_loaded,
}
