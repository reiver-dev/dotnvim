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

let s:id = expand('<SID>')

function! s:BufferRegistryStateId(expr) abort
    let l:State = getbufvar(a:expr, "__buffer_state_ref_holder__", v:null)
    if l:State != v:null
        return l:State()
    else
        return v:null
    endif
endfunction

let s:opts = {
            \ 'varname': '__buffer_registry_state_ref_holder__',
            \ 'funcname': s:id . 'BufferRegistryStateId'
            \}

call luaeval('require("bufreg")._setup(_A)', s:opts)

" bufreg.vim ends here
