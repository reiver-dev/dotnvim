--- Lua and VimL callbacks
--

require "bootstrap.interop.trampouline"
local command = require "bootstrap.interop.command"
local au = require "bootstrap.interop.autocommand"


local function config_path()
    return vim.fn["stdpath"]('config')
end


return {
    config_path = config_path,
    command = command.make,
    augroup = au.augroup,
    autocmd = au.autocmd,
}
