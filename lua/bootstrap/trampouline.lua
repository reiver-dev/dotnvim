--- Global trampouline function

function _trampouline(modname, funcname, ...)
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
        error ("Failed to find function %s:%s"):format(modname, funcname)
    end
    return mod[funcname](...)
end

--- trampouline.lua ends here
