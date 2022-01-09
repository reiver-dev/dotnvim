local uv = vim.loop

local os_is_posix = {
    Darwin = true,
    Linux = true,
    Unix = true,
    Windows = false,
    Windows_NT = false,
    MINGW32_NT = false,
}

local os_is_win = {
    Windows = true,
    Windows_NT = true,
    MINGW32_NT = true,
}


local osname

local name = uv.os_uname().sysname
if name ~= nil and os_is_posix[name] ~= nil then
    osname = name
else
    local has = vim.fn.has
    if has("macunix") then
        osname = "Darwin"
    elseif has("unix") then
        osname = "Unix"
    elseif has("win32") then
        osname = "Windows"
    elseif has("wsl") then
        osname = "Linux"
    else
        osname = "Unix"
    end
end

local is_posix = os_is_posix[osname] or false
local is_win = os_is_win[osname] or false

return {
    osname = osname,
    is_posix = is_posix,
    is_win = is_win,
}
