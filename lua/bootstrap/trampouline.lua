--- Global trampouline function
--

local function tget(tbl, key)
    return tbl[key]
end


local function find(modname, funcname)
    local mod

    if modname ~= nil and modname ~= "" then
        mod = package.loaded[modname]
        if mod == nil then
            mod = require(modname)
        end
    else
        mod = _G
    end

    if funcname == nil or funcname == "" then
        if not vim.is_callable(mod) then
            error(("Module is not callable: %s"):format(modname))
        end
        return mod
    end

    local ok, func = pcall(tget, mod, funcname)
    if not ok then
        error(("Failed to index module %s:%s"):format(modname, funcname))
    end
    if func == nil then
        error(("Failed to find function %s:%s"):format(modname, funcname))
    end
    if not vim.is_callable(func) then
        error(("Function is not callable %s:%s"):format(modname, funcname))
    end

    return func
end


local function trampouline(modname, funcname, ...)
    return find(modname, funcname)(...)
end


local function setup()
    _G._T = trampouline
end


return {
    setup = setup,
    trampouline = trampouline,
}

--- trampouline.lua ends here
