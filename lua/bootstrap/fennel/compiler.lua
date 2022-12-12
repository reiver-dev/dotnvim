--- Fennel lisp compiler initialization
--

local M = {}

local fennel = require "fennel"
local basic = require "bootstrap.basic"

--- @param state function
--- @param idx number
--- @return number|nil
--- @return string|nil
--- @return any
local function upvalues_iter(state, idx)
    idx = idx + 1
    local name, value = debug.getupvalue(state, idx)
    if name ~= nil then
        return idx, name, value
    end
end


--- @param func function
--- @return fun(function, number), function, number
local function upvalues(func)
    return upvalues_iter, func, 0
end

--- @return table?
local function extract_sourcemap()
    for _, name, value in upvalues(fennel.traceback) do
        if name == "traceback_frame" then
            for _, uname, uvalue in upvalues(value) do
                if uname == "sourcemap" then
                    return uvalue
                end
            end
            break
        end
    end
end


M.sourcemap = extract_sourcemap()


local function compile_source(text, opts)
    return pcall(fennel.compileString, text, opts)
end


M.compile_source = compile_source


function M.compile_file(src, dst, opts)
    local text = basic.slurp(src):gsub("\r\n", "\n")
    local compiled, code = compile_source(text, opts)
    if compiled then
        vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
        basic.spew(dst, code)
    else
        local msg = ("Failed compile: %s\n%s"):format(src, code)
        vim.api.nvim_err_writeln(msg)
    end
end


local function find_macro_fnl(name)
    local basename = string.gsub(name, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local found = basic.runtime(paths)
    if found ~= nil then
        return found
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
    "LOG",
    "_T",
    "LOAD_PACKAGE",
    "RELOAD",
}, {__newindex = function() error("Allowed globals insert attempt") end})


local function macro_loader(_, fname)
    return fennel.dofile(fname, {env = "_COMPILER", compilerEnv = MACRO_ENV})
end


local function lua_macro_loader(_, fname)
    local data = basic.slurp(fname)
    return fennel['load-code'](data, fennel['make-compiler-env'], fname)
end


function M.compiler_env()
    return MACRO_ENV
end


function M.allowed_globals()
    return ALLOWED_GLOBALS
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

    local found = basic.runtime(paths)
    if found then
        if string.sub(found, -3) == "fnl" then
            return macro_loader, found
        else
            return lua_macro_loader, found
        end
    end
end


function M.compiler_init()
    local searchers = fennel["macro-searchers"]
    table.insert(searchers, 1, macro_searcher)
end


function M.initialize()
    M.compiler_init()
    M.initialize = function() end
end

return M
