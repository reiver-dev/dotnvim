local M = {}

local cachedir = vim.fn.stdpath('cache'):gsub("\\", "/") .. "/fennel/"
local basic = require "bootstrap.basic"

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


local function complete_fennel(arg, _, pos)
    return require("bootstrap.fennel.repl").complete(arg, pos)
end


local function compile_and_load(srcfile, dstfile)
    local text = basic.slurp(srcfile)

    local mod = "bootstrap.fennel.compiler"
    local compiler = package.loaded[mod] or require(mod)
    compiler.initialize()

    local opts = {
        filename = srcfile,
        useMetadata = false,
        allowedGlobals = compiler.allowed_globals(),
        compilerEnv = compiler.compiler_env(),
    }

    local compiled, code = compiler.compile_module_source(text, opts)
    if compiled then
        basic.spew(dstfile, code)
        return loadstring(code, '@' .. dstfile)
    end

    return nil, ("Failed compile: %s\n%s"):format(srcfile, code)
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
        error(string.format("Fnl file error %s %s", srcfile, srcerr))
    end

    local needcompile
    if dststat == nil then
        if dsterr:gsub(":.*", "") ~= "ENOENT" then
            error(string.format("Fail to compile %s into %s: %s",
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
            return string.format("Fail to compile %s into %s: %s",
                                 modname, dstfile, dsterr)
        end
        return
    end

    local basename = string.gsub(modname, "%.", "/")
    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local srcfile = basic.runtime(paths)
    if srcfile then
        local srcstat, srcerr = uv.fs_stat(srcfile)
        if srcstat == nil then
            if dststat then
                os.remove(dstfile)
            end
            error(string.format("Fnl file error %s %s", srcfile, srcerr))
        end

        if srcstat.mtime.sec < dststat.mtime.sec then
            local code = basic.slurp(dstfile)
            return select_result(loadstring(code, '@' .. dstfile))
        end
        return select_result(compile_and_load(srcfile, dstfile))
    end
end


local function module_searcher(modname)
    local basename = string.gsub(modname, "%.", "/")

    local f = string.format
    local paths = {
        f("fnl/%s.fnl", basename),
        f("fnl/%s/init.fnl", basename),
    }

    local found = basic.runtime(paths)
    if found then
        return select_result(ensure_cached(modname, found))
    end
end


function M.setup()
    M.ensure_modules()

    table.insert(package.loaders, 3, module_searcher)
    table.insert(package.loaders, 2, expedite_cached_searcher)

    vim.api.nvim_add_user_command(
        "EvalExpr",
        function(...) require("bootstrap.fennel.repl").eval_print(...) end,
        {
            desc = "bootstrap.fennel.repl::eval_print",
            complete = complete_fennel,
            nargs = 1,
        }
    )
end

return M
