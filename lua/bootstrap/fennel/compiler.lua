--- Fennel lisp compiler initialization
--

local M = {}

local fennel = require "fennel"
local basic = require "bootstrap.basic"

function M.compile_module_source(text, opts)
    local code = "(require-macros \"aniseed.macros\")" .. text
    return xpcall(function() return fennel.compileString(code, opts) end,
                  fennel.traceback)
end


function M.compile_source(text, opts)
    return xpcall(function() return fennel.compileString(text, opts) end,
                  fennel.traceback)
end


function M.compile_file(src, dst, opts)
    local text = basic.slurp(src)
    local compiled, code = M.compile_module_source(text, opts)
    if compiled then
        vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
        basic.spew(dst, code)
    else
        local msg = ("Failed compile: %s\n%s"):format(src, code)
        vim.api.nvim_err_writeln(msg)
    end
end


local function macro_loader(modname, fname)
    return fennel.dofile(fname, {env = "_COMPILER"})
end


local function macro_searcher(name)
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
            return macro_loader, found
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


function M.compiler_init()
    LOAD_PACKAGE("conjure")
    local searchers = fennel["macro-searchers"]
    if #searchers == 1 then
        table.insert(searchers, 1, macro_searcher)
        table.insert(searchers, aniseed_macro_searcher)
    end
end


function M.initialize()
    M.compiler_init()
    M.initialize = function() end
end

return M
