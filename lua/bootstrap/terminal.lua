--- Terminal settings 

local M = {}


local cmd = [[
augroup boostrap_terminal
autocmd!
autocmd TermOpen * setlocal nonumber norelativenumber
augroup end
]]


function M.setup()
    vim.api.nvim_exec(cmd, false)
end


return M

--- terminal.lua ends here
