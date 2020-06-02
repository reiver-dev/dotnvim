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

--- loaded.lua ends here
