local M = {}


local function gather_files(root, force)
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
            if force or getftime(srcpath) > getftime(dstpath) then
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


    local aniseed = function(name)
        return "conjure." .. name
    end

    package.preload["fennelview"] = fennelview

    package.preload["aniseed.deps.fennel"] = fennel
    package.preload["aniseed.deps.fennelview"] = fennelview
    package.preload["aniseed.autoload"] = aniseed

    package.preload["conjure.aniseed.deps.fennel"] = fennel
    package.preload["conjure.aniseed.deps.fennelview"] = fennelview

end


function M.compile(force)
    local cfg = vim.fn.stdpath('config'):gsub('\\', '/')
    local sources = gather_files(cfg, force)
    local afterfiles = gather_files(cfg .. "/after", force)

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

    local errors = {}

    for src, dst in pairs(sources) do
        opts.filename = src
        local ok, result = pcall(fennel.compile_file, src, dst, opts, true)
        if not ok then
            errors[#errors + 1] = ("Failed to compile %s: %s"):format(src, result)
        end
    end

    for src, dst in pairs(afterfiles) do
        opts.filename = src
        local ok, result = pcall(fennel.compile_file, src, dst, opts, true)
        if not ok then
            errors[#errors + 1] = ("Failed to compile %s: %s"):format(src, result)
        end
    end

    if next(errors) then
        error(table.concat(errors, "\n"))
    end
end


local function complete_fennel(arg, line, pos)
    return require("bootstrap.fennel.repl").complete(arg, pos)
end


function M.init()
    interop = require"bootstrap.interop"

    local def = interop.command{
        name = "EvalExpr",
        nargs = 1,
        complete = "customlist,v:lua.__complete_fennel",
        modname = "bootstrap.fennel.repl",
        funcname = "eval_print"
    }
    _G.__complete_fennel = complete_fennel
    vim.api.nvim_command(def)

    def = interop.command{
        name = "InitRecompile",
        nargs = "*",
        modname = "bootstrap.fennel",
        funcname = "compile",
        bang = "!",
    }
    vim.api.nvim_command(def)
end


function M.setup()
    M.ensure_modules()
    M.compile()
    M.init()
end

return M
