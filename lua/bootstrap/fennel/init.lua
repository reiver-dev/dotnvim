local M = {}


local function gather_files(root)
    local result = {}
    local srcdir = root .. "/fnl"
    local dstdir = root .. "/lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        if not srcpath:match(".*macros.fnl") then
            local srcpath = srcpath:gsub("\\", "/")
            local suffix = srcpath:sub(prefixlen + 1)
            local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
            if getftime(srcpath) > getftime(dstpath) then
                result[srcpath] = dstpath
            end
        end
    end
    return result
end


function M.ensure_modules()
    local fennel = function()
        return require "fennel"
    end

    local fennelview = function()
        return require "fennel.view"
    end

    package.preload["fennelview"] = fennelview

    package.preload["aniseed.deps.fennel"] = fennel
    package.preload["aniseed.deps.fennelview"] = fennelview 

    package.preload["conjure.aniseed.deps.fennel"] = fennel
    package.preload["conjure.aniseed.deps.fennelview"] = fennelview 
end


function M.compile()
    local cfg = vim.fn.stdpath('config'):gsub('\\', '/')
    local sources = gather_files(cfg) 
    local afterfiles = gather_files(cfg .. "/after")

    if vim.tbl_isempty(sources) and vim.tbl_isempty(afterfiles) then
        return
    end

    local fennel = require("bootstrap.fennel.compiler")
    fennel.initialize()

    local opts = {
        useMetadata = false,
        compilerEnv = _G,
        ["compiler-env"] = _G
    }

    for src, dst in pairs(sources) do
        opts.filename = src
        fennel.compile_file(src, dst, opts, true)
    end

    for src, dst in pairs(afterfiles) do
        opts.filename = src
        fennel.compile_file(src, dst, opts, true)
    end
end


function M.init()
    interop = require"bootstrap.interop"

    local def = interop.command{
        name = "EvalExpr",
        nargs = 1,
        modname = "bootstrap.fennel.repl",
        funcname = "eval_print"
    }
    vim.api.nvim_command(def)

    def = interop.command{
        name = "InitRecompile",
        nargs = "*",
        modname = "bootstrap.fennel",
        funcname = "compile"
    }
    vim.api.nvim_command(def)
end


function M.setup()
    M.ensure_modules()
    M.compile()
    M.init()
end

return M
