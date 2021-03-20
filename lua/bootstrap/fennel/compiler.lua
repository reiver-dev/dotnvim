--- Fennel lisp compiler initialization
--

local M = {}

local fennel = require "fennel"

function M.compile_source(text, opts)
    local code = "(require-macros \"aniseed.macros\")" .. text
    return xpcall(function() return fennel.compileString(code, opts) end,
                  fennel.traceback)
end


local function slurp(path)
    local fd, err = io.open(path, "r")
    if fd == nil then
        return false, err
    end
    local ok, data = pcall(function () return fd:read("*all") end)
    fd:close()
    return ok, data
end


local function spew(path, text)
    local fd, err = io.open(path, "w")
    if fd == nil then
        return false, err
    end
    local ok, res = pcall(function() return fd:write(text) end)
    fd:close()
    return ok, res
end


function M.compile_file(src, dst, opts, force)
    if force ~= nil or vim.fn.getftime(src) > vim.fn.getftime(dst) then
        local ok, text = slurp(src)
        if ok then
            local compiled, code = M.compile_source(text, opts)
            if compiled then
                vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")
                spew(dst, code)
            else
                local msg = ("Failed compile: %s\n%s"):format(src, code)
                vim.api.nvim_err_writeln(msg)
            end
        end
    end
end


function M.compiler_init()
    LOAD_PACKAGE("conjure")
    local macros = vim.api.nvim_get_runtime_file("lua/conjure/aniseed/macros.fnl", false)[1]
    local aniseed_root = vim.fn.fnamemodify(macros, ":h:h")
    local fnl_root = vim.fn.stdpath("config") .. "/fnl"
    fennel.path = ("%s/?.fnl;%s/?.fnl;%s"):format(aniseed_root, fnl_root, fennel.path)
end


function M.initialize()
    M.compiler_init()
    M.initialize = function() end
end

return M
