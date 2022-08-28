--- Path string manipulation

local MOD = ...
local sysname = vim.loop.os_uname().sysname

local mod
if (sysname == "Windows"
    or sysname == "Windows_NT"
    or sysname == "MINGW32_NT") then
    mod = require(MOD .. ".win")
else
    mod = require(MOD .. ".posix")
end

return mod

--- path init.lua ends here
