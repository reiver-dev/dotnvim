--- Terminal settings 

vim.api.nvim_exec([[
augroup boostrap_terminal
    autocmd!
    autocmd TermOpen * setlocal nonumber norelativenumber
    autocmd TermOpen * startinsert
augroup end
]], false)

--- terminal.lua ends here
