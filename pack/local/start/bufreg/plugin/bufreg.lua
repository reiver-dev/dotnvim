--- Buffer registry setup

local loaded = vim.g.loaded_buffer_registry

if loaded and loaded == 1 then
    return
end

vim.g.loaded_buffer_registry = 1

local bufreg = require "bufreg"

vim.api.nvim_create_autocmd(
    {
        "VimEnter", "BufNew", "BufNewFile", "BufReadPre"
    },
    {
        group = vim.api.nvim_create_augroup("bufreg", { clear = false }),
        callback = bufreg._autocmd_new,
    }
)

bufreg._setup {
    varname='__buffer_registry_state_ref_holder__',
}

--- plugin/bufreg.lua ends here
