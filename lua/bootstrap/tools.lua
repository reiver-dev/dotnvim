--- Lua utilities
--
-- Taken from lume 
--     https://github.com/rxi/lume/blob/master/lume.lua
--


local unpack = rawget(table, "unpack") or unpack


--- Returns shallow copy of the table t
local function clone(t)
  local rtn = {}
  for k, v in pairs(t) do rtn[k] = v end
  return rtn
end


--- Iterates the supplied iterator and returns an array filled with the values.
--
local function array(...)
  local t = {}
  for x in ... do t[#t + 1] = x end
  return t
end


--- Returns true if x is an array.
--
-- The value is assumed to be an array if it is a table which contains
-- a value at the index 1. 
--
local function isarray(x)
  return type(x) == "table" and x[1] ~= nil
end


--- Rounds x to the nearest integer.
--
-- Rounds away from zero if we're midway between two integers. If increment is
-- set then the number is rounded to the nearest increment.
--
local function round(x, increment)
  if increment then return round(x / increment) * increment end
  return x >= 0 and math_floor(x + .5) or math_ceil(x - .5)
end


--- Returns 1 if x is 0 or above, returns -1 when x is negative.
--
local function sign(x)
  return x < 0 and -1 or 1
end


--- Prints the current filename and line number followed by each argument
-- separated by a space.
local function trace(...)
  local info = debug.getinfo(2, "Sl")
  local t = { info.short_src .. ":" .. info.currentline .. ":" }
  for i = 1, select("#", ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = string.format("%g", round(x, .01))
    end
    t[#t + 1] = tostring(x)
  end
  print(table.concat(t, " "))
end


--- Escape lua string pattern speifiers.
--
local function patternescape(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end


--- Returns an array of the words in the string str.
--
-- If sep is provided it is used as the delimiter, consecutive delimiters are
-- not grouped together and will delimit empty strings.
--
local function split(str, sep)
  if not sep then
    return array(str:gmatch("([%S]+)"))
  else
    assert(sep ~= "", "empty separator")
    local psep = patternescape(sep)
    return array((str..sep):gmatch("(.-)("..psep..")"))
  end
end


--- Returns a formatted string.
--
-- The values of keys in the table vars can be inserted into the string
-- by using the form "{key}" in str; numerical keys can also be used.
--
local function format(str, vars)
  if not vars then return str end
  local f = function(x)
    return tostring(vars[x] or vars[tonumber(x)] or "{" .. x .. "}")
  end
  return (str:gsub("{(.-)}", f))
end


-- Trims the whitespace from the start and end of the string str and returns
-- the new string. If a chars value is set the characters in chars are trimmed
-- instead of whitespace.
--
local function trim(str, chars)
  if not chars then return str:match("^[%s]*(.-)[%s]*$") end
  chars = patternescape(chars)
  return str:match("^[" .. chars .. "]*(.-)[" .. chars .. "]*$")
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
        if updated[old] then return end
        updated[old] = true
        local oldmt, newmt = getmetatable(old), getmetatable(new)
        if oldmt and newmt then update(oldmt, newmt) end
        for k, v in pairs(new) do
            if type(v) == "table" then update(old[k], v) else old[k] = v end
        end
    end
    local err = nil
    local function onerror(e)
        for k in pairs(_G) do _G[k] = oldglobal[k] end
        err = trim(e)
    end
    local ok, oldmod = pcall(require, modname)
    oldmod = ok and oldmod or nil
    xpcall(function()
            package.loaded[modname] = nil
            local newmod = require(modname)
            if type(oldmod) == "table" then update(oldmod, newmod) end
            for k, v in pairs(oldglobal) do
                if v ~= _G[k] and type(v) == "table" then
                    update(v, _G[k])
                    _G[k] = v
                end
            end
           end, onerror)
    package.loaded[modname] = oldmod
    if err then return nil, err end
    return oldmod
end


return {
    trim = trim,
    clone = clone,
    patternescape = patternescape,
    hotswap = hotswap
}
