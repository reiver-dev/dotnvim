--- Compile fennel compiler
--


local M = {}

local basic = require("bootstrap.basic")


local function compile(fennel, src, env)
    local options = {
        filename = src,
        requireAsInclude = false,
        useMetadata = false,
        compilerEnv = env,
        allowedGlobals = false,
    }
    local srcdata = basic.slurp(src)
    return fennel['compile-string'](srcdata, options)
end


--- @param root string
--- @return string[]
local function collect(root)
    local result = {}
    local i = 0
    local match = string.match
    local sroot = root:gsub("[\\/]*$", "/")
    for name, type in vim.fs.dir(root, { depth = 4 }) do
        if type == "file" and match(name, ".*fennel.*%.fnl$")
            and not match(name, ".*macros%.fnl$")
            and not match(name, ".*match%.fnl$") then
            i = i + 1
            result[i] = sroot .. name
        end
    end
    return result
end

--- @param path string
--- @return integer
local function getftime(path)
    local stat = vim.loop.fs_stat(path)
    if not stat then
        return -1
    end
    return stat.mtime.sec
end


local function gather_files(root, force)
    if root == nil or root == "" then
        error("Empty root dir")
    end
    local result = {}
    local srcdir = root .. "/src"
    local dstdir = root .. "/rtp/lua"
    local prefixlen = srcdir:len()
    local sources = collect(srcdir)
    for _, srcpath in ipairs(sources) do
        local suffix = srcpath:sub(prefixlen + 1)
        local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
        if force or getftime(srcpath) > getftime(dstpath) then
            result[srcpath] = dstpath
        end
    end
    return result
end


local function ensure_global(_, k)
    local msg = string.format("Attempt to get key: %s", k)
    error(msg)
end


local function forbid_new_global(_, k, v)
    local msg = string.format("Attempt to set value: %s := %s",
                              k, vim.inspect(v))
    error(msg)
end


local strict_global = {
    __index = ensure_global,
    __newindex = forbid_new_global
}

local forbid_insert = {
    __newindex = forbid_new_global
}


local function is_simple_type(t)
    return t == "table" or t == "function" or t == "boolean" or t == "number"
end

local function protect(tbl)
    local result = {}
    for key, val in pairs(tbl) do
        local t = type(val)
        if not is_simple_type(t) then
            local msg = string.format("Unexpected type(%s): %s => %s",
                                      t, key, vim.inspect(val))
            error(msg)
        end
        if t == "table" then
            result[key] = protect(tbl)
        else
            result[key] = val
        end
    end
    return setmetatable(result, forbid_insert)
end

local function open_ro(path, mode)
    if mode ~= nil and string.match(mode, "[wa]") ~= nil then
        error(string.format("Unexpected io.open mode: %s", mode))
    end
    return io.open(path, mode)
end

local function make_compiler_env(environ)
    if environ == nil then
        environ = {}
    end

    local _package = {
        config = package.config,
        loaded = {},
        preload = {}
    }

    local _require = function(k)
        if _package.loaded[k] ~= nil then
            return _package.loaded[k]
        end
        local m = _package.preload[k](k)
        _package.loaded[k] = m
        return m
    end

    local baseenv = {
        _ENV = false,
        _VERSION = _VERSION,
        package = _package,
        require = _require,
        unpack = unpack,
        pcall = pcall,
        xpcall = xpcall,
        string = protect(string),
        io = setmetatable({ open = open_ro, read = io.read }, strict_global),
        table = protect(table),
        bit = protect(bit),
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        setfenv = setfenv,
        getfenv = getfenv,
        error = error,
        assert = assert,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        math = protect(math),
        tostring = tostring,
        tonumber = tonumber,
        select = select,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        next = next,
        print = print,
        debug = setmetatable({ traceback = debug.traceback }, strict_global),
        os = setmetatable({
            getenv = function(k)
                return environ[k]
            end
        }, strict_global)
    }

    local _G = baseenv
    baseenv._G = _G

    do
        local _load = load
        function baseenv.load(...)
            local this_env = getfenv()
            local f, msg = _load(...)
            if f then
                return setfenv(f, this_env), msg
            end
            return f, msg
        end
        setfenv(baseenv.load, baseenv)
    end

    do
        local _loadstring = loadstring
        function baseenv.loadstring(...)
            local this_env = getfenv()
            local f, msg = _loadstring(...)
            if f then
                return setfenv(f, this_env), msg
            end
            return f, msg
        end
        setfenv(baseenv.loadstring, baseenv)
    end

    return setmetatable(baseenv, strict_global)
end

function M.old_setup(opts)
    local force = opts and opts.force
    local dry_run = opts and opts.dry_run

    local old_path = basic.runtime({ "bootstrap/fennel.lua", "old/fennel.lua" })
    if old_path == nil or old_path == "" then
        error("Fennel old compiler not found")
    end

    local old_fennel_loader, errmsg = loadfile(old_path)
    if old_fennel_loader == nil then
        error("Failed to load fennel: " .. errmsg)
    end

    local root = vim.fn.fnamemodify(old_path, ":p:h:h")
    assert(root ~= nil and root ~= "", "Empty fennel path")
    vim.notify("Fennel root: " .. root)

    local baseenv = make_compiler_env({
        FENNEL_SRC = root,
        FENNEL_PATH = root .. "src/?.fnl",
    })
    setfenv(old_fennel_loader, baseenv)
    local old_fennel = old_fennel_loader("fennel")

    if force and not dry_run then
        local dir = root .. "/rtp/lua"
        vim.notify("Removing " .. dir)
        basic.rmdir(dir)
    end

    local ok, res = xpcall(function()
        for src, dst in pairs(gather_files(root, force)) do
            vim.notify(string.format("Compiling %s => %s", src, dst))
            local compiled = compile(old_fennel, src, baseenv)
            if not dry_run then
                basic.spew(dst, compiled)
            end
        end
    end, debug.traceback)

    if not ok then
        error(res)
    end
end


local function aot(root, input, opts)
    local cmd = {
        vim.uv.exepath(),
        "--clean",
        "-l",
        "bootstrap/aot.lua",
        input
    }

    if opts and opts.macro then
        table.insert(cmd, "--macro")
    end

    vim.notify(vim.inspect(cmd), vim.log.levels.DEBUG)

    local result = vim.system(cmd, { cwd = root, text = true }):wait()

    if result.code == 0 and result.signal == 0 then
        if not result.stderr or result.stderr == "" then
            error("empty output")
        end
        return result.stderr
    end

    local msg = string.format("Exited: %d (%d)\nOUTPUT: %s", result.code, result.signal, result.stderr)
    error(msg)
end

local function aot_save(root, input, output, opts)
    local dst = vim.fs.joinpath(root, output)
    vim.notify(string.format("Compiling %s => %s", input, dst))
    local compiled = aot(root, input, opts)
    if not (opts and opts.dry_run) then
        basic.spew(dst, compiled)
    end
end

function M.setup(opts)
    local force = opts and opts.force
    local dry_run = opts and opts.dry_run

    local old_path = basic.runtime({ "bootstrap/fennel.lua", "old/fennel.lua" })
    if old_path == nil or old_path == "" then
        error("Fennel old compiler not found")
    end

    local root = vim.fn.fnamemodify(old_path, ":p:h:h")
    assert(root ~= nil and root ~= "", "Empty fennel path")
    vim.notify("Fennel root: " .. root)

    aot_save(root, "src/fennel/macros.fnl", "bootstrap/macros.lua", {macro = true, dry_run = dry_run})
    aot_save(root, "src/fennel/match.fnl", "bootstrap/match.lua", {macro = true, dry_run = dry_run})

    local ok, res = xpcall(function()
        for src, dst in pairs(gather_files(root, force)) do
            vim.notify(string.format("Compiling %s => %s", src, dst))
            local compiled = aot(root, src)
            if not dry_run then
                basic.spew(dst, compiled)
            end
        end
    end, debug.traceback)

    if not ok then
        error(res)
    end
end

return M


-- ensure_compiler.lua ends here
