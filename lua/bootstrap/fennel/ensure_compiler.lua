--- Compile fennel compiler
--


local M = {}

local basic = require("bootstrap.basic")


local function compile(fennel, src, dst, env)
    local options = {
        filename = path,
        requireAsInclude = false,
        useMetadata = false,
        compilerEnv = env,
        allowedGlobals = false,
    }
    local srcdata = basic.slurp(src)
    local dstdata = fennel['compile-string'](srcdata, options)
    basic.spew(dst, dstdata)
end


local function gather_files(force)
    local result = {}
    local srcdir = "src"
    local dstdir = "lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        if not srcpath:match(".*macros.fnl$") then
            local srcpath = srcpath:gsub("\\", "/")
            local suffix = srcpath:sub(prefixlen + 1)
            local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
            if force or getftime(srcpath) > getftime(dstpath) then
                result[srcpath] = dstpath
            end
        end
    end
    return result
end


local function ensure_global(t, k)
    local msg = string.format("Attempt to get key: %s", k)
    error(msg)
end


local function forbid_new_global(t, k, v)
    local msg = string.format("Attempt to set value: %s := %s",
                              k, vim.inspect(v))
    error(msg)
end


local strict_global = {
    __index = ensure_global,
    __newindex = forbid_new_global
}


local function pick(base, ...)
    local result = {}
    for i = 1, select("#", ...) do
        local k = select(i, ...)
        result[k] = base[k]
    end
    return setmetatable(result, strict_global)
end


local function make_compiler_env()
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

    local baseenv
    local baseenv = {
        package = _package,
        require = _require,
        unpack = unpack or table.unpack,
        pcall = pcall,
        xpcall = xpcall,
        string = string,
        io = io,
        table = table,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        error = error,
        assert = assert,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        math = math,
        tostring = tostring,
        tonumber = tonumber,
        select = select,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        next = next,
        print = print,
        debug = setmetatable({traceback = debug.traceback}, strict_global),
        os = {
            getenv = function(k)
                return nil
            end
        }
    }

    local _G = baseenv
    baseenv._G = _G

    baseenv.load = function(...)
        return load(...)
    end

    return setmetatable(baseenv, strict_global)

end


function M.setup(opts)
    local force = opts and opts.force
    local old_path = vim.api.nvim_get_runtime_file("old/fennel.lua", false)[1]
    if old_path == nil or old_path == "" then
        error("Fennel old compiler not found")
    end

    local old_fennel_loader, errmsg = loadfile(old_path)
    if old_fennel_loader == nil then
        error("Failed to load fennel: " .. errmsg)
    end

    local baseenv = make_compiler_env()
    setfenv(old_fennel_loader, baseenv)
    local old_fennel = old_fennel_loader("fennel")

    local root = vim.fn.fnamemodify(old_path, ":p:h:h")

    if force then
        local dir = root .. "/lua"
        vim.notify("Removing " .. dir)
        basic.rmdir(dir)
    end

    local ok, res = pcall(basic.with_dir, root, function()
        for src, dst in pairs(gather_files()) do
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
