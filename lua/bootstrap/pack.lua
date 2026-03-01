--- vim.pack extention

local modules = require "bootstrap.modules"
local autoload = require "bootstrap.autoload"

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
---@field after string[]?
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


---@alias set {string:{string:true}}

---@type {string:string}
local _pack_pending_event = {}


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
local function on_pack_event(pack, ev)
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
local function on_pack_changed(ev)
    local evd = ev.data
    local spec = evd.spec
    _pack_pending_event[spec.name] = evd.kind
end

---@param pack {spec: my.pack.SpecResolved, path: string}
local function pack_load(pack)
    local spec = pack.spec

    if not spec.data then
        _pack_pending_event[spec.name] = nil
        packadd(pack.spec.name)
        return
    end

    local ev = _pack_pending_event[spec.name]
    if ev then
        on_pack_event(pack, ev)
    end

    on_pack_event(pack, "init")

    if spec.data.opt then
        autoload.schedule(spec.name, spec.data)
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

    nvim_create_autocmd("PackChanged", {
        group = g,
        callback = on_pack_changed,
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
end


return {
    resolve = resolve,
    setup = setup,
    add = add,
    load_pkg = load_pkg,
}

--- bootstrap/pack.lua ends here
