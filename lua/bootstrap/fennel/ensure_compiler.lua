--- Compile fennel compiler
--


local M = {}

local basic = require("bootstrap.basic")


local function compile(fennel, src, dst)
    local options = {
        filename = path,
        requireAsInclude = false,
        useMetadata = false,
    }
    basic.spew(dst, fennel.compileString(basic.slurp(src), options))
end


local function gather_files(force)
    local result = {}
    local srcdir = "src"
    local dstdir = "lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        if not srcpath:match(".*macros.fnl$") then
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


function M.setup(opts)
    local force = opts and opts.force
    local old_path = vim.api.nvim_get_runtime_file("old/fennel.lua", false)[1]

    local old_fennel = loadfile(old_path)
    setfenv(old_fennel, setmetatable({}, {__index = _G}))
    old_fennel = old_fennel()

    local root = vim.fn.fnamemodify(old_path, ":p:h:h")

    if force then
        local dir = root .. "/lua"
        vim.notify("Removing " .. dir)
        basic.rmdir(dir)
    end

    local old = package.loaded.fennel
    package.loaded.fennel = fennel

    local ok, res = pcall(basic.with_dir, root, function()
        for src, dst in pairs(gather_files()) do
            vim.notify(string.format("Compiling %s => %s", src, dst))
            compile(old_fennel, src, dst)
        end
    end)

    package.loaded.fennel = old

    if not ok then
        error(res)
    end
end


return M


-- ensure_compiler.lua ends here
