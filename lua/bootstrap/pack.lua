--- vim.pack extention

local modules = require "bootstrap.modules"

local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_exec_autocmds = vim.api.nvim_exec_autocmds
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_del_augroup_by_name = vim.api.nvim_del_augroup_by_name
local nvim_create_user_command = vim.api.nvim_create_user_command
local nvim_call_function = vim.api.nvim_call_function
local nvim_set_keymap = vim.api.nvim_set_keymap
local nvim_del_keymap = vim.api.nvim_del_keymap
local nvim_input = vim.api.nvim_input
local nvim_feedkeys = vim.api.nvim_feedkeys
local nvim_del_user_command = vim.api.nvim_del_user_command

local nvim_cmd = vim.api.nvim_cmd

---@alias my.pack.ConfigCallback fun(pkginfo: my.pack.Package)

---@alias my.pack.KeyMod 
---| '"i"'
---| '"n"'

---@class my.pack.KeySpec
---@field [1] my.pack.KeyMod
---@field [2] string

---@class my.pack.Pkg
---@field name string
---@field url string
---@field opt boolean
---@field disable boolean?
---@field after string|string[]?
---@field cmd string|string[]?
---@field event string|string[]?
---@field ft string|string[]?
---@field module string|string[]?
---@field requires string|string[]?
---@field keys my.pack.KeySpec[]?
---@field rtp string|string[]?
---@field run my.pack.ConfigCallback?
---@field config my.pack.ConfigCallback?
---@field setup my.pack.ConfigCallback?

---@class my.pack.SpecData
---@field opt boolean?
---@field cmd string[]?
---@field event string[]?
---@field ft string[]?
---@field module string[]?
---@field requires string[]?
---@field rtp string[]?
---@field run my.pack.ConfigCallback?
---@field config my.pack.ConfigCallback?
---@field setup my.pack.ConfigCallback?

---@class my.pack.Spec : vim.pack.Spec
---@field data my.pack.SpecData

---@class my.pack.SpecResolved
---@field name string
---@field src string
---@field path string
---@field active boolean
---@field data my.pack.SpecData

---@class my.pack.Package
---@field spec my.pack.SpecResolved
---@field path string
---@field version nil|string|vim.VersionRange?
---@field rev string?


local NO_INFO = {info = false}

---@param names string[]?
---@return my.pack.Package[]
local function pack_get(names)
    return vim.pack.get(names, NO_INFO)
end


---@param pack my.pack.Package
local function ensure_rtp(pack)
    local root = pack.path
    local rtp = pack.spec.data.rtp
    for _, p in ipairs(rtp) do
        ---@diagnostic disable-next-line: undefined-field
        vim.opt.runtimepath:append(vim.fs.joinpath(root, p))
    end
end


---@param path string
local function source_after(path)
    local loc = vim.fs.joinpath(path, "after/plugin/**/*.{vim,lua}")
    local after_paths = vim.fn.glob(loc, false, true)
    for _, p in ipairs(after_paths) do
        vim.cmd.source({ p, magic = { file = false } })
    end
end

local _pack_hook_augroup = nil

---@alias set {string:{string:true}}

---@type {string:string}
local _pack_event = {}

---@type set
local _pack_ft = {}

local _pack_modmap = {}

local _pack_after = {}

local _pack_after_target = {}

local _pack_loaded = {}


---@alias my.pack.Event
---| '"install"'
---| '"update"'
---| '"delete"'
---| '"init"'


local function packadd(name)
    modules.load_package(name)
    -- vim.cmd.packadd({
    --     vim.fn.escape(name, ' '),
    --     magic = { file = false },
    -- })
end

---@param set {string:{string:true}}
---@param pkgname string
---@param names string[]
local function set_add(set, pkgname, names)
    for _, name in ipairs(names) do
        local subset = set[name]
        if subset then
            subset[pkgname] = true
        end
    end
end


---@param set {string:{string:true}}
---@param pkgname string
---@param names string[]
local function set_remove(set, pkgname, names)
    for _, name in ipairs(names) do
        local subset = set[name]
        if subset then
            subset[pkgname] = nil
        end
    end
end


local function nest(tbl, key)
    local v = tbl[key]
    if not v then
        v = {}
        tbl[key] = v
    end
    return v
end


local function modmap_add(pkgname, mods)
    local opt = {plain = true, trimempty = true}
    local modmap = _pack_modmap
    for _, mod in ipairs(mods) do
        local mm = modmap
        for part in vim.gsplit(mod, ".", opt) do
            mm = nest(mm, part)
        end
        local pkgs = nest(mm, true)
        pkgs[pkgname] = true
    end
end


local function modmap_del(pkgname, mods)
    local opt = {plain = true, trimempty = true}
    local modmap = _pack_modmap
    for _, mod in ipairs(mods) do
        local mm = modmap
        for part in vim.gsplit(mod, ".", opt) do
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
    local opt = {plain = true, trimempty = true}
    local modmap = _pack_modmap
    local result = {}
    local mm = modmap
    if not mm then
        return result
    end
    local ir = 1
    for part in vim.gsplit(mod, ".", opt) do
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
    local target = _pack_after_target[name]
    if not target then
        target = {}
        _pack_after_target[name] = target
    end
    local after = _pack_after
    local loaded = _pack_loaded
    for _, dep in ipairs(deps) do
        if not loaded[dep] then
            local a = after[dep]
            if a then
                a[#a + 1] = name
            else
                after[dep] = {name}
            end
            target[dep] = true
        end
    end
end


---@param name string
---@return string[]?
local function dependency_trigger(name)
    local deps = _pack_after[name]
    if not deps then
        return
    end
    _pack_after[name] = nil
    local result
    local i = 0
    local target = _pack_after_target
    for _, dep in ipairs(deps) do
        local t = target[dep]
        if t and t[name] then
            t[name] = nil
            if not next(t) then
                target[dep] = nil
                if i == 0 then
                    i = 1
                    result = {dep}
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
    local target = _pack_after_target[name]
    if not target then
        return
    end
    local deps = _pack_after
    _pack_after_target[name] = nil
    for t in pairs(target) do
        local d = deps[t]
        if d then
            array_remove(d, name)
        end
    end
end


local _EMPTY = {}


---@param cmdargs vim.api.keyset.create_user_command.command_args
---@return vim.api.keyset.cmd
local function prepare_cmd(cmdargs)
    local count
    local range
    local reg

    if cmdargs.range == 1 then
        count = cmdargs.count
    elseif cmdargs.range == 2 and (cmdargs.line1 or cmdargs.line2) then
        range = {cmdargs.line1, cmdargs.line2}
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


local function clear_loaders(pkg)
    local spec = pkg.spec
    local name = spec.name
    local data = spec.data
    if not data then
        return
    end

    if data.cmd then
        for _, cmdname in ipairs(data.cmd) do
            nvim_del_user_command(cmdname)
        end
    end

    if data.keys then
        for _, mapping in ipairs(data.keys) do
            local mode = mapping[1]
            local key = mapping[2]
            nvim_del_keymap(mode, key)
        end
    end

    if data.event then
        nvim_del_augroup_by_name("my.pack.hook/" .. spec.name)
    end

    if data.ft then
        set_remove(_pack_ft, name, data.ft)
    end

    if data.module then
        modmap_del(name, data.module)
    end

    if data.after then
        dependency_clear(name)
    end
end



---@param pkgname string
local function on_autoload(pkgname)
    local pkgs = pack_get({pkgname}, {info = false})
    for _, pkg in ipairs(pkgs) do
        clear_loaders(pkg)
    end
    packadd(pkgname)
end


local function on_command(pkgname, cmdargs)
    on_autoload(pkgname)
    nvim_cmd(prepare_cmd(cmdargs), _EMPTY)
end


local function on_command_complete(pkgname)
    on_autoload(pkgname)
end


local function on_filetype(ev)
    local ft = _pack_ft[ev.file]
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
            local opts = {callback = false}
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
                    comparg = {cmdname .. " ", "cmdline"}
                end
                return nvim_call_function("getcompletion", comparg)
            end,
        }
        nvim_create_user_command(cmdname, action, opts)
    end
end


local function schedule_filetypes(pkgname, filetypes)
    for _, filetype in ipairs(filetypes) do
        local ft = _pack_ft[filetype]
        if ft then
            ft[pkgname] = true
        else
            ft = {pkgname}
            _pack_ft[filetype] = ft
        end
    end
end


---@param pkgname string
---@param events string[]
local function schedule_events(pkgname, events)
    local group = nvim_create_augroup("my.pack.hook/" .. pkgname, {clear = true})
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


---@params pack my.pack.SpecResolved
local function schedule_autoload(pack)
    local pkgname = pack.spec.name
    local data = pack.spec.data

    if data.cmd then
        schedule_commands(pkgname, data.cmd)
    end

    if data.keys then
        schedule_keys(pkgname, data.keys)
    end

    if data.ft then
        schedule_filetypes(pkgname, data.ft)
    end

    if data.event then
        schedule_events(pkgname, data.event)
    end

    if data.module then
        schedule_modules(pkgname, data.module)
    end

    if data.after then
        schedule_after(pkgname, data.after)
    end
end


---@param arg nil|string|string[]
---@returns nil|string[]
local function strlist(arg)
    if not arg then return end
    if arg == "" then return end
    if type(arg) == "string" then return {arg} end
    if type(arg) == "table" then
        if not arg[1] then return end
        return arg
    end
end


---@param spec my.pack.Pkg
---@return my.pack.Spec?
local function resolve(spec)
    if spec.disable then
        return nil
    end

    local opt = spec.opt
    local disable = spec.disable
    local after = strlist(spec.after)
    local cmd = strlist(spec.cmd)
    local event = strlist(spec.event)
    local ft = strlist(spec.ft)
    local module = strlist(spec.module)
    local requires = strlist(spec.requires)
    local keys = spec.keys
    local run = spec.run
    local config = spec.config
    local setup = spec.setup

    if ft or module or keys or event or after then
        opt = true
    end

    if requires and after then
        local joined = {}
        local j = 0
        for _, pkg in ipairs(requires) do
            j = j + 1
            joined[j] = pkg
        end
        for _, pkg in ipairs(after) do
            j = j + 1
            joined[j] = pkg
        end
        requires = joined
    end

    local data = {
        opt = opt,
        disable = disable,
        after = after,
        cmd = cmd,
        event = event,
        ft = ft,
        module = module,
        requires = requires,
        keys = keys,
        run = run,
        config = config,
        setup = setup,
    }

    if not next(data) then
        data = nil
    end

    return {
        name = spec.name,
        src = spec.url,
        data = data,
    }
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


local function load_package_specs()
    local path = vim.fs.joinpath(vim.fn.stdpath("config"), "pkg.lua")
    local mod, err = assert(loadfile(path))
    if mod == nil then
        vim.notify(err:gsub("\t", "    "), vim.log.levels.ERROR)
        return
    end
    return mod
end


---@return my.pack.Spec[]?
local function load_packages()
    local mod = load_package_specs()
    if not mod then return end

    local packages = {}
    local i = 0
    local function pkg(spec)
        if spec and not spec.disable then
            i = i + 1
            packages[i] = spec
        end
    end

    mod(pkg)

    local specs = {}
    for j = 1,i do
        specs[j] = resolve(packages[j])
    end

    return specs
end


---@param pack my.pack.Package
---@param ev my.pack.Event
local function on_event(pack, ev)
    local spec = pack.spec
    local data = spec.data

    if data.run then
        if ev == "install" or ev == "update" then
            data.run(pack)
        end
    end

    if data.setup then
        local ok, err = xpcall(function() data.setup(pack) end, debug.traceback)
        if not ok then
            local msg = string.format("Error during (%s) setup: %s", spec.name, err)
            vim.notify(msg, vim.log.levels.ERROR)
        end
    end

    if data.requires then
        modules.eval_before_load(spec.name, function()
            modules.load_package(unpack(data.requires))
        end)
    end

    if data.config or data.rtp then
        modules.eval_after_load(spec.name, function()
            if pack.spec.data.rtp then
                ensure_rtp(pack)
            end
            if pack.spec.data.config then
                pack.spec.data.config(pack)
            end
        end)
    end
end


---@param ev any
local function on_hook(ev)
    local evd = ev.data
    local spec = evd.spec
    _pack_event[spec.name] = evd.kind
end

---@param pack {spec: my.pack.SpecResolved, path: string}
local function pack_load(pack)
    local spec = pack.spec

    if not spec.data then
        _pack_event[spec.name] = nil
        packadd(pack.spec.name)
        return
    end

    local ev = _pack_event[spec.name]
    if ev then
        on_event(pack, ev)
    end

    on_event(pack, "init")

    if spec.data.opt then
        schedule_autoload(pack)
    else
        packadd(pack.spec.name)
        if vim.v.vim_did_enter == 1 then
            source_after(pack.path)
        end
        return
    end
end


---@param pkgs my.pack.Spec[]
local function add(pkgs)
    vim.pack.add(pkgs, {
        load = pack_load,
        confirm = false,
    })
end


local function load_pkg()
    local specs = load_packages()
    if specs then
        local ok, err = xpcall(function()
            add(specs)
        end, debug.traceback)
        if not ok then
            local msg = "Failed to run vim.pack.add: " .. err
            vim.notify(msg, vim.log.levels.ERROR)
        end
    end
end


local function package_complete(prefix, filter)
    local pkgs = {}
    local i = 0
    for _, p in ipairs(pack_get(nil)) do
        if (not filter or filter(p)) and vim.startswith(p.spec.name, prefix) then
            i = i + 1
            pkgs[i] = p.spec.name
        end
    end
    table.sort(pkgs)
    return pkgs
end


local function package_open_dir(names, command_mods)
    local pkgs = pack_get(names)
    local paths = {}
    for _, pkg in ipairs(pkgs) do
        paths[pkg.spec.name] = pkg.path
    end
    for _, name in ipairs(names) do
        local path = paths[name]
        if path then
            vim.cmd(
                (command_mods or "")
                .. " split "
                .. vim.fn.fnameescape(path)
            )
        end
    end
end


local function package_execute_run(names)
    local pkgs = pack_get(names)
    for _, pkg in ipairs(pkgs) do
        local data = pkg.spec.data
        if data and data.run then
            local ok, err = xpcall(function() pkg.spec.data.run(pkg) end, debug.traceback)
            if not ok then
                local msg = string.format("Pack (%s) run step failed: %s", pkg.spec.name, err)
                vim.notify(msg, vim.log.levels.ERROR)
            end
        end
    end
end


local function setup()
    local g = nvim_create_augroup("my.pack", { clear = true })
    _pack_hook_augroup = nvim_create_augroup("my.pack.hook", { clear = true })

    table.insert(package.loaders, 2, loader)

    nvim_create_autocmd("FileType", {
        group = _pack_hook_augroup,
        callback = on_filetype,
    })

    nvim_create_autocmd("PackChanged", {
        group = g,
        callback = on_hook,
    })

    nvim_create_user_command("PackOpen", function(opts)
        package_open_dir(opts.fargs, opts.mods)
    end, {nargs = "*", complete = function(prefix)
        return package_complete(prefix)
    end})

    nvim_create_user_command("PackMake", function(opts)
        package_execute_run(opts.fargs)
    end, {nargs = "*", complete = function(prefix)
        return package_complete(prefix, function(pkg)
            local data = pkg.spec.data
            return data and data.run
        end)
    end})

    modules.eval_after_any_load(function(pkgname)
        _pack_loaded[pkgname] = true
        on_dependency(pkgname)
    end)
end


local function get_loaders()
    local res = {}
    for i, l in ipairs(package.loaders) do
        local info = debug.getinfo(l, "Sn")
        res[i] = info
    end
    return res
end


local function get_depmap()
    return _pack_after_target, _pack_after
end


local function get_modmap()
    return _pack_modmap
end


local function get_loaded()
    return _pack_loaded
end


return {
    resolve = resolve,
    setup = setup,
    add = add,
    loader = loader,
    load_pkg = load_pkg,
    modmap = get_modmap,
    depmap = get_depmap,
    loaded = get_loaded,
    debug_loaders = get_loaders,
}

--- bootstrap/pack.lua ends here
