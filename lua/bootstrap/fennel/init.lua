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


function M.compile()
    local cfg = vim.fn.stdpath('config'):gsub('\\', '/')
    local sources = gather_files(cfg) 
    local afterfiles = gather_files(cfg .. "/after")
    local opts = { useMetadata = true, ["compiler-env"] = _G }

    if vim.tbl_isempty(sources) and vim.tbl_isempty(afterfiles) then
        return
    end

    local fennel = require"bootstrap.fennel.compiler"
    fennel.initialize()

    for src, dst in pairs(sources) do
        opts.filename = src
        fennel.compile_file(src, dst, {}, true)
    end

    for src, dst in pairs(afterfiles) do
        opts.filename = src
        fennel.compile_file(src, dst, {}, true)
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

return M
