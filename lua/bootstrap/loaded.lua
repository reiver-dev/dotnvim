--- Track loaded vim files
--

local cmd = [[
augroup loaded_tracking
autocmd!
autocmd SourcePost * :call v:lua._register_loaded(expand('<afile>'))
augroup END
]]


local M = {}

M.loaded_vim = {}

function M.register_loaded(file)
    table.insert(M.loaded_vim, file)
end

function M.setup()
    vim.api.nvim_exec(cmd, nil)
    _register_loaded = M.register_loaded
end

return M

--- loaded.lua ends here
