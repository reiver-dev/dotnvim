--- Fennel lisp compiler initialization
--

local M = {}

local fennel = require "fennel"
local basic = require "bootstrap.basic"


local function upvalues_iter(state, idx)
    idx = idx + 1
    local name, value = debug.getupvalue(state, idx)
    if name ~= nil then
        return idx, name, value
    end
end


local function upvalues(func)
    return upvalues_iter, func, 0
end


local function extract_sourcemap(mod)
    for i, name, value in upvalues(fennel.traceback) do
        if name == "traceback_frame" then
            for i, name, value in upvalues(value) do
                if name == "fennel_sourcemap" then
                    return value
                end
            end
            break
        end
    end
end


M.sourcemap = extract_sourcemap(fennel)


local function compile_source(text, opts)
    return pcall(fennel.compileString, text, opts)
end


M.compile_source = compile_source


local FIX_ANISEED_MACROS = ""
.. "(macro defonce- [name value] `(def- ,name (or (. *module-locals* ,(tostring name)) ,value)))"
.. "(macro defonce [name value] `(def ,name (or (. *module-locals* ,(tostring name)) ,value)))"


function M.compile_module_source(text, opts)
    local file
    if opts.filename == nil then
        file = "nil"
    else
        file = string.format("%q", opts.filename)
    end
    local filevar = string.format([[(local *file* %s)]], file)
    local code = filevar .. "(require-macros \"aniseed.macros\")" .. FIX_ANISEED_MACROS .. text
    local delete_pat = "\n[^\n]-\"ANISEED_DELETE_ME\".-"
    _G.ANISEED_STATIC_MODULES = true
    local ok, res, sm = compile_source(code, opts)
    if ok then
	res = string.gsub(res, delete_pat .. "\n", "\n")
	res = string.gsub(res, delete_pat .. "$", "")
    end
    return ok, res, sm
end


function M.compile_file(src, dst, opts)
    local text = basic.slurp(src):gsub("\r\n", "\n")
    local compiled, code = M.compile_module_source(text, opts)
    if compiled then
        vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
        basic.spew(dst, code)
    else
        local msg = ("Failed compile: %s\n%s"):format(src, code)
        vim.api.nvim_err_writeln(msg)
    end
end


local function find_macro(basename)
    local basename = string.gsub(name, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
        f("lua/%s.lua", basename),
        f("lua/%s/init.lua", basename),
    }

    local get = vim.api.nvim_get_runtime_file

    for _, path in ipairs(paths) do
        local found = get(path, false)[1]
        if found ~= nil then
            return found
        end
    end
end


local function find_macro_fnl(name)
    local basename = string.gsub(name, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local get = vim.api.nvim_get_runtime_file

    for _, path in ipairs(paths) do
        local found = get(path, false)[1]
        if found ~= nil then
            return found
        end
    end
end


local function load_macro_ast(modname)
    local found = find_macro_fnl(modname)
    if found then
        local text = basic.slurp(found)
        local chunks = {}
        for ok, ast in fennel.parser(fennel['string-stream'](text)) do
            if ok then
                chunks[#chunks+1] = ast
            end
        end
        return chunks
    end
end


local MACRO_ENV = setmetatable({
    package = package,
    pairs = pairs,
    ipairs = ipairs,
    type = type,
    table = table,
    tostring = tostring,
    tonumber = tonumber,
    string = string,
    select = select,
    assert = assert,
    error = error,
    require = require,
    debug = debug,
    print = print,
    pcall = pcall,
    xpcall = xpcall,
    loadast = load_macro_ast,
    getmetatable = getmetatable,
    setmetatable = setmetatable,
    _SYSNAME = vim.loop.os_uname().sysname,
}, {__newindex = function() error("Macro env insert attempt") end})


local ALLOWED_GLOBALS = setmetatable({
    -- builtin
    "tonumber",
    "tostring",
    "error",
    "pcall",
    "xpcall",
    "loadfile",
    "load",
    "loadstring",
    "dofile",
    "gcinfo",
    "collectgarbage",
    "newproxy",
    "print",
    "require",
    "assert",
    "type",
    "next",
    "pairs",
    "ipairs",
    "getmetatable",
    "setmetatable",
    "getfenv",
    "setfenv",
    "rawget",
    "rawset",
    "rawequal",
    "unpack",
    "select",
    "_VERSION",
    -- modules
    "package",
    "coroutine",
    "debug",
    "table",
    "string",
    "math",
    "io",
    "os",
    "jit",
    "bit",
    "_G",
    -- globals
    "vim",
    "log",
    "_T",
    "_trampouline",
    "LOAD_PACKAGE",
    "RELOAD",
}, {__newindex = function() error("Allowed globals insert attempt") end})


local function macro_loader(modname, fname)
    return fennel.dofile(fname, {env = "_COMPILER", compilerEnv = MACRO_ENV})
end


local function lua_macro_loader(modname, fname)
    local data = basic.slurp(fname)
    return fennel['load-code'](data, fennel['make-compiler-env'], fname)
end


function M.compiler_env()
    return MACRO_ENV
end


function M.allowed_globals()
    return ALLOWED_GLOBALS
end


function M.module_searcher(name)
    M.initialize()

    local basename = string.gsub(name, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local get = vim.api.nvim_get_runtime_file
    for _, path in ipairs(paths) do
        local found = get(path, false)[1]
        if found then
            local code, err = ensure_cached(name, found)
            if code then
                local f, err = loadstring(code, name)
                if err then
                    return err
                end
                return f
            else
                return function() error(err) end
            end
        end
    end
end


local function macro_searcher(name)
    local basename = string.gsub(name, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
        f("lua/%s.lua", basename),
        f("lua/%s/init.lua", basename),
    }

    local get = vim.api.nvim_get_runtime_file

    for _, path in ipairs(paths) do
        local found = get(path, false)[1]
        if found then
            if string.sub(found, -3) == "fnl" then
                return macro_loader, found
            else
                return lua_macro_loader, found
            end
        end
    end

    return nil
end


local function aniseed_macro_searcher(name)
    if name ~= "aniseed.macros" then
        return nil
    end
    local path = vim.api.nvim_get_runtime_file("lua/conjure/aniseed/macros.fnl", false)[1]
    if not path then
        return nil
    end
    return macro_loader, path
end


function M.resolve_path()
    local filesep, pathsep, submask
    do
        local it = string.gmatch(package.config, "([^\n]+)")
        filesep = it() or "/"
        pathsep = it() or ";"
        submask = it() or "?"
    end

    local fnl_tail = string.format("%s.fnl", submask)
    local fnl_base = table.concat({
        ".", filesep, submask, ".fnl", pathsep,
        ".", filesep, submask, filesep, "init.fnl",
    })

    local newpath = {fnl_base}

    local paths = vim.api.nvim_get_runtime_file("fnl/", true)
    for i, path in ipairs(paths) do
        newpath[#newpath + 1] = path .. fnl_tail
    end

    local aniseed_path = vim.api.nvim_get_runtime_file("lua/conjure/aniseed/macros.fnl", false)[1]
    if aniseed_path then
        newpath[#newpath + 1] = aniseed_path
    end

    return table.concat(newpath, ";")
end


function M.compiler_init()
    LOAD_PACKAGE("conjure")
    local searchers = fennel["macro-searchers"]
    if type(searchers) == 'table' then
        table.insert(searchers, 1, macro_searcher)
        table.insert(searchers, aniseed_macro_searcher)
    else
        fennel.path = M.resolve_path()
    end
end


function M.initialize()
    M.compiler_init()
    M.initialize = function() end
end

return M
