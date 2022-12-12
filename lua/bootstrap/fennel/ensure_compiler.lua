--- Compile fennel compiler
--


local M = {}

local basic = require("bootstrap.basic")


local function compile(fennel, src, dst, env)
    local options = {
        filename = src,
        requireAsInclude = false,
        useMetadata = false,
        compilerEnv = env,
        allowedGlobals = false,
    }
    local srcdata = basic.slurp(src)
    local dstdata = fennel['compile-string'](srcdata, options)
    basic.spew(dst, dstdata)
end


--- @param root string
--- @param pattern string
--- @return string[]
local function glob(root, pattern)
    return vim.fn.globpath(root, pattern, true, true)
end


local function gather_files(root, force)
    if root == nil or root == "" then
        error("Empty root dir")
    end
    local result = {}
    local srcdir = root .. "/src"
    local dstdir = root .. "/lua"
    local prefixlen = srcdir:len()
    local sources = glob(srcdir, "**/*.fnl")
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        if not srcpath:match(".*macros.fnl$") then
            srcpath = srcpath:gsub("\\", "/")
            local suffix = srcpath:sub(prefixlen + 1)
            local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
            if force or getftime(srcpath) > getftime(dstpath) then
                result[srcpath] = dstpath
            end
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
        _VERSION = _VERSION,
        package = _package,
        require = _require,
        unpack = unpack or table.unpack,
        pcall = pcall,
        xpcall = xpcall,
        string = protect(string),
        io = setmetatable({open = open_ro}, strict_global),
        table = protect(table),
        bit = protect(bit),
        setmetatable = setmetatable,
        getmetatable = getmetatable,
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
        debug = setmetatable({traceback = debug.traceback}, strict_global),
        os = setmetatable({
            getenv = function(k)
                return environ[k]
            end
        }, strict_global)
    }

    local _G = baseenv
    baseenv._G = _G

    function baseenv.load(...)
        return load(...)
    end

    return setmetatable(baseenv, strict_global)

end


function M.setup(opts)
    local force = opts and opts.force
    local old_path = basic.runtime({"bootstrap/fennel.lua", "old/fennel.lua"})
    if old_path == nil or old_path == "" then
        error("Fennel old compiler not found")
    end

    local old_fennel_loader, errmsg = loadfile(old_path)
    if old_fennel_loader == nil then
        error("Failed to load fennel: " .. errmsg)
    end

    local root = vim.fn.fnamemodify(old_path, ":p:h:h")
    assert(root ~= nil and root ~= "", "Empty fennel path")

    local baseenv = make_compiler_env({FENNEL_SRC = root})
    setfenv(old_fennel_loader, baseenv)
    local old_fennel = old_fennel_loader("fennel")

    if force then
        local dir = root .. "/lua"
        vim.notify("Removing " .. dir)
        basic.rmdir(dir)
    end

    local ok, res = pcall(function()
        for src, dst in pairs(gather_files(root)) do
            vim.notify(string.format("Compiling %s => %s", src, dst))
            compile(old_fennel, src, dst, baseenv)
        end
    end)

    if not ok then
        error(res)
    end
end


return M


-- ensure_compiler.lua ends here
