--- Global trampouline function
--


local M = {}


local function accept(status, ...)
    if status then
        return ...
    end
    error(...)
end


local function error_handler(modname, funcname)
    return function (...)
        local data = vim.inspect{...}
        local msg = ("\n\tTrampoiline %s::%s\n\t%s"):format(modname, funcname, data)
        return debug.traceback(msg)
    end
end


local function find(modname, funcname)
    local mod
    if modname ~= nil and #modname > 0 then
        mod = package.loaded[modname]
        if mod == nil then
            mod = require(modname)
        end
    else
        mod = _G
    end
    local func = mod[funcname]
    if func == nil then
        error(("Failed to find function %s:%s"):format(modname, funcname))
    end
    return func
end


function M.trampouline(modname, funcname, ...)
    return accept(xpcall(find(modname, funcname),
                         error_handler(modname, funcname),
                         ...))
end


function M.setup()
    _trampouline = M.trampouline
    _T = M.trampouline
end


return M

--- trampouline.lua ends here
