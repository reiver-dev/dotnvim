--- Trivial helpers
--

local M = M or {}


function M.slurp(path)
    local f = io.open(path, "rb")
    local ok, result = pcall(function() return f:read("*all") end)
    f:close()
    if not ok then
        error(result)
    end
    return result
end


function M.spew(path, data) 
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local f = io.open(path, "wb") 
    local ok, result = pcall(function()
        return f:write(data)
    end)
    f:close()
    if not ok then
        error(result)
    end
    return result
end


function M.with_dir(dir, func)
    local cwd = vim.fn.getcwd()
    vim.cmd("cd " .. dir)
    local ok, res = xpcall(func, debug.traceback)
    vim.cmd("cd " .. cwd)
    if not ok then
        error(res)
    end
    return res
end


return M

--- basic.lua ends here
