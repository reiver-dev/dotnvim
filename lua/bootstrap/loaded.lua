--- Track loaded vim files
--

_package_loaded = {}
_loaded_vim = {}

_register_loaded = function(file) 
    table.insert(_loaded_vim, file)
end

vim.cmd "\
autocmd! SourcePost *\
:call v:lua._register_loaded(expand('<afile>')) \
"

local M = {}


function M.loadpackage(name)
    vim.api.nvim_command("packadd " .. name)
    _package_loaded[name] = true
end


function M.loadall(name)
    vim.api.nvim_command("packloadall")
end



--- loaded.lua ends here
