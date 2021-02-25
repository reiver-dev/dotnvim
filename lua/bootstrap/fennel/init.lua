local M = {}


local function gather_files(root)
    local result = {}
    local srcdir = root .. "/fnl"
    local dstdir = root .. "/lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        local srcpath = srcpath:gsub("\\", "/")
        local suffix = srcpath:sub(prefixlen + 1)
        local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
        if getftime(srcpath) > getftime(dstpath) then
            result[srcpath] = dstpath
        end
    end
    return result
end


local function preload_wrap(name)
    package.preload[name] = function(...)
        require "fennel"
        return package.preload["aniseed." .. name](...)
    end
end


function M.ensure_modules()
    package.preload["fennel"] = function()
        return require "aniseed.deps.fennel"
    end
    package.preload["fennel.view"] = function ()
        return require "aniseed.deps.fennelview"
    end
    package.preload["fennelview"] = package.preload["fennel.view"]
    preload_wrap("fennel.parser")
    preload_wrap("fennel.compiler")
    preload_wrap("fennel.specials")
    preload_wrap("fennel.utils")
    preload_wrap("fennel.friend")
    preload_wrap("fennel.repl")
end


function M.compile()
    local cfg = vim.fn.stdpath('config'):gsub('\\', '/')
    local sources = gather_files(cfg) 
    local afterfiles = gather_files(cfg .. "/after")
    local opts = {
        useMetadata = false,
        compilerEnv = _G,
        ["compiler-env"] = _G
    }

    if vim.tbl_isempty(sources) and vim.tbl_isempty(afterfiles) then
        return
    end

    local fennel = require"bootstrap.fennel.compiler"
    fennel.initialize()

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
    require"my".setup()
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
