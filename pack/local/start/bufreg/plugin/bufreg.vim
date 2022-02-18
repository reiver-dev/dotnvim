" Buffer registry setup

if exists('g:loaded_buffer_registry')
  finish
endif

let g:loaded_buffer_registry = 1

augroup buffer_registry
autocmd!
autocmd VimEnter * lua require("bufreg")._autocmd_new()
autocmd BufNew,BufNewFile * lua require("bufreg")._autocmd_new()
autocmd BufReadPre * lua require("bufreg")._autocmd_new()
augroup END

lua require("bufreg")._setup({varname='__buffer_registry_state_ref_holder__'})

" bufreg.vim ends here
