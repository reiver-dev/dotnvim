--- Configuration reload procedures
--

local SELF = "bootstrap.reload"
local trim = vim.trim


--- Returns shallow copy of the table t
local function clone(t)
  local rtn = {}
  for k, v in pairs(t) do rtn[k] = v end
  return rtn
end


--- Reload lua module
--
-- Reloads an already loaded module in place, allowing you to immediately see
-- the effects of code changes without having to restart the program.
-- modname should be the same string used when loading the module with require().
-- In the case of an error the global environment is restored and nil plus an
-- error message is returned.
--
local function hotswap(modname)
    local oldglobal = clone(_G)
    local updated = {}

    local function update(old, new)
        if updated[old] then
            return
        end
        updated[old] = true

        local oldmt = getmetatable(old)
        local newmt = getmetatable(new)
        if oldmt and newmt then
            update(oldmt, newmt)
        end

        for k, v in pairs(new) do
            if type(v) == "table" then
                update(old[k], v)
            else
                old[k] = v
            end
        end
    end

    local err = nil

    local function onerror(e)
        for k in pairs(_G) do
            _G[k] = oldglobal[k]
        end
        err = trim(e)
    end

    local ok, oldmod = pcall(require, modname)
    oldmod = ok and oldmod or nil

    xpcall(function()
        package.loaded[modname] = nil
        local newmod = require(modname)

        if type(oldmod) == "table" then
            update(oldmod, newmod)
        end

        for k, v in pairs(oldglobal) do
            if v ~= _G[k] and type(v) == "table" then
                update(v, _G[k])
                _G[k] = v
            end
        end
    end, onerror)

    package.loaded[modname] = oldmod

    if err then
        return nil, err
    end

    return oldmod
end


local function reload_self()
    hotswap(SELF)
end


local function reload_modules(...)
    local errors = {}
    for _, n in ipairs({...}) do
        local _, err = hotswap(n)
        table.insert(errors, err)
    end
    if #errors > 0 then
        error(table.concat(errors, '\n'))
    end
end


local function complete_module()
    return table.concat(vim.tbl_keys(package.loaded), "\n")
end


local COMMAND = [[
command! -nargs=+ -complete=custom,v:lua.__complete_module ReloadModule lua RELOAD(<f-args>)
]]


local function setup()
    _G.RELOAD = reload_modules
    _G.__complete_module = complete_module
    vim.api.nvim_exec(COMMAND, false)
end


return {
    setup = setup,
    reload = reload_modules,
    selfreload = reload_self
}
