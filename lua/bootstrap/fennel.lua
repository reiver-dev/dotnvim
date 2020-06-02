--- Fennel lisp initialization
--

local compile = require "aniseed.compile"
local fennel = require "aniseed.fennel"
local view = require("aniseed.view").serialise

local dir = vim.api.nvim_call_function("stdpath", {"config"}):gsub("\\", "/")
local root = dir .. "/fnl/"

local my = {}
my["specials"] = {}
local specials = my["specials"]


local function filename_to_module(path)
    path = string.gsub(path, root, "")
    path = string.gsub(path, "(.*)%.fnl$", "%1")
    path = string.gsub(path, "/", ".")
    return path
end


local function currentfile(ast, scope, parent, opts)
    if nil ~= ast.filename then
        return string.format("%q", ast.filename)
    else
        return "\"<unknown>\""
    end
end


local function currentmodule(ast, scope, parent, opts)
    if nil ~= ast.filename then
        return string.format("%q", (filename_to_module(ast.filename)))
    else
        return "\"<unknown>\""
    end
end


local function debugscope(ast, scope, parent, opts)
    return string.format("%q", view(scope))
end


local function debugast(ast, scope, parent, opts)
    return string.format("%q", view(ast))
end


local function debugparent(ast, scope, parent, opts)
    return string.format("%q", view(parent))
end


local function debugopts(ast, scope, parent, opts)
    return string.format("%q", view(opts))
end


local function debugall(ast, scope, parent, opts)
    local data = {
        ast = ast,
        scope = scope,
        parent = parent,
        opts = opts
    }
    return string.format("%q", view(data))
end


local function modcall(ast, scope, parent, opts)
    if #ast < 2 then
        error(string.format("Must have >3 args: %s", vim.inspect(ast)))
    end

    local result = fennel.list()
    local mm = {string.match(ast[2], "(.*)/(.*)")}
    if #mm > 0 then
        result[1] = fennel.list(
            fennel.sym("."),
            fennel.list(
                fennel.sym("require"),
                mm[1]
            ),
            mm[2]
        )
    else
        result[1] = ast[2]
    end

    local i = 2
    local a = 3
    local len = #ast
    while a <= len do
        result[i] = ast[a]
        i = i + 1
        a = a + 1
        len = len - 1
    end

    return fennel.compile1(result, scope, parent, opts)
end


local function compile_source(text, opts)
    local code = "(require-macros \"aniseed.macros\")\n" .. text
    return xpcall(function() return fennel.compileString(code, opts) end,
                  fennel.traceback)
end


local function compile_source2(text, opts)
    local code = "(import-macros [:module] \"aniseed.macros\")\n" .. text
    return xpcall(function() return fennel.compileString(code, opts) end,
                  fennel.traceback)
end


local function slurp(path)
    local fd, err = io.open(path, "r")
    if fd == nil then
        return false, err
    end
    local data = fd:read("*all")
    fd:close()
    return true, data
end


local function spew(path, text)
    local fd, err = io.open(path, "w")
    if fd == nil then
        return false, err
    end
    local res = fd:write(text)
    fd:close()
    return true, res
end


local function compile_file(src, dst, opts, force)
    if force ~= nil or vim.fn.getftime(src) > vim.fn.getftime(dst) then
        local ok, text = slurp(src)
        if ok then
            local compiled, code = compile_source(text, opts)
            if compiled then
                vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
                spew(dst, code)
            else
                vim.api.nvim_err_writeln(code)
            end
        end
    end
end


local function recompile()
    local srcdir = dir .. "/fnl"
    local dstdir = dir .. "/lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    for _, srcpath in ipairs(sources) do
        local srcpath = srcpath:gsub("\\", "/")
        local suffix = srcpath:sub(prefixlen + 1)
        local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
        compile_file(srcpath, dstpath, { filename = suffix:sub(2) })
    end
end


local function compiler_init()
    fennel.path = fennel.path:gsub('\\', '/')
    fennel.eval [[
    (eval-compiler
       (local fnl (require :bootstrap.fennel))
       (tset _SPECIALS :debug-scope fnl.specials.debugscope)
       (tset _SPECIALS :debug-ast fnl.specials.debugast)
       (tset _SPECIALS :debug-parent fnl.specials.debugparent)
       (tset _SPECIALS :debug-opts fnl.specials.debugopts)
       (tset _SPECIALS :debug-all fnl.specials.debugall)
       (tset _SPECIALS :current-file fnl.specials.currentfile)
       (tset _SPECIALS :current-module fnl.specials.currentmodule)
       (tset _SPECIALS :! fnl.specials.modcall)
    )
    ]]
end


local function eval(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.eval(opts.rawargs, options)
end


local function eval_print(opts)
    print(view(eval(opts)))
end


local function repl(opts, env)
    local options = {
        env = setmetatable({ _A = opts }, {__index = env or _ENV or _G})
    }
    return fennel.repl(options)
end


specials["currentfile"] = currentfile
specials["currentmodule"] = currentmodule
specials["debugscope"] = debugscope
specials["debugast"] = debugast
specials["debugparent"] = debugparent
specials["debugopts"] = debugopts
specials["debugall"] = debugall
specials["modcall"] = modcall

my["recompile"] = recompile
my["eval"] = eval
my["repl"] = repl
my["eval_print"] = eval_print
my["compiler_init"] = compiler_init
my["compile_file"] = compile_file


return my

--- fennel.lua ends here
