local M = {}

local cachedir = vim.fn.stdpath('cache'):gsub("\\", "/") .. "/fennel/"
local basic = require "bootstrap.basic"


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


local function compile_and_load(srcfile, dstfile)
    local opts = {
        useMetadata = false,
        compilerEnv = _G,
        ["compiler-env"] = _G,
        filename = srcfile,
    }
    local text = basic.slurp(srcfile)

    local compiler = require("bootstrap.fennel.compiler")
    compiler.initialize()

    local compiled, code = compiler.compile_module_source(text, opts)
    if compiled then
        basic.spew(dstfile, code)
        return loadstring(code, '@' .. dstfile)
    end

    return nil, ("Failed compile: %s\n%s"):format(src, code)
end


local function select_result(result, err)
    if result ~= nil then
        return result
    end
    return err
end


local function ensure_cached(modname, srcfile)
    local dstfile = cachedir .. modname .. ".lua"
    local uv = vim.loop

    local srcstat, srcerr = uv.fs_stat(srcfile)
    local dststat, dsterr = uv.fs_stat(dstfile)

    if srcstat == nil then
        if dststat then
            os.remove(dstfile)
        end
        error(string.format("Fnl file error %s %s", fname, srcerr))
    end

    local needcompile
    if dststat == nil then
        if dsterr:gsub(":.*", "") ~= "ENOENT" then
            error(string.format("Fail to compile %s into %s:",
                                srcfile, dstfile, dsterr))
        end
        needcompile = true
    else
        needcompile = srcstat.mtime.sec >= dststat.mtime.sec
    end

    if needcompile then
        return compile_and_load(srcfile, dstfile)
    end

    return loadfile(dstfile)
end


local function expedite_cached_searcher(modname)
    local dstfile = cachedir .. modname .. ".lua"
    local uv = vim.loop

    local dststat, dsterr = uv.fs_stat(dstfile)
    if dststat == nil then
        if dsterr:gsub(":.*", "") ~= "ENOENT" then
            return string.format("Fail to compile %s into %s:",
                                 srcfile, dstfile, dsterr)
        end
        return
    end

    local basename = string.gsub(modname, "%.", "/")
    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local get = vim.api.nvim_get_runtime_file
    for _, path in ipairs(paths) do
        local srcfile = get(path, false)[1]
        if srcfile then
            local srcstat, srcerr = uv.fs_stat(srcfile)
            if srcstat == nil then
                if dststat then
                    os.remove(dstfile)
                end
                error(string.format("Fnl file error %s %s", fname, srcerr))
            end

            if srcstat.mtime.sec < dststat.mtime.sec then
                local code = basic.slurp(dstfile)
                return select_result(loadstring(code, '@' .. dstfile))
            end
            return select_result(compile_and_load(srcfile, dstfile))
        end
    end
end


local function module_searcher(modname)
    local basename = string.gsub(modname, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local get = vim.api.nvim_get_runtime_file
    for _, path in ipairs(paths) do
        local found = get(path, false)[1]
        if found then
            return select_result(ensure_cached(modname, found))
        end
    end
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
    -- M.compile()
    table.insert(package.loaders, 2, module_searcher)
    table.insert(package.loaders, 1, expedite_cached_searcher)
    M.init()
end

return M
