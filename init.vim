""" Main nvim config
"""

function! s:clipboard_set(name)
    return { lines, regtype -> v:lua.setclipboard(lines, regtype, name) }
endfunction


function! s:clipboard_get(name)
    return { -> v:lua.getclipboard(name) }
endfunction


function! ClipboardReset()
    unlet! g:loaded_clipboard_provider
    runtime autoload/provider/clipboard.vim
endfunction


function! ClipboardSetup()
    let g:clipboard = {
                \ 'name': 'bootstrap',
                \     'copy': {
                \         '+': call s:clipboard_set('+'),
                \         '*': call s:clipboard_set('*'),
                \     },
                \     'paste': {
                \         '+': call s:clipboard_get('+'),
                \         '*': call s:clipboard_get('*'),
                \     },
                \ }
endfunction


function! s:has_element(obj, key)
    return type(a:obj) == v:t_dict && has_key(a:obj, a:key) || 
         \ type(a:obj) == v:t_list && 0 <= a:key && a:key < len(a:obj) 
endfunction


function! EvalMember(obj, path) abort
    let pt = type(a:path)

    if pt == v:t_dict
        for [k, v] in items(a:path)
	    if s:has_element(a:obj, k)
                call EvalMember(a:obj[k], v)
            endif
        endfor
    elseif pt == v:t_list
	let k = 1
        for v in a:path
	    if s:has_element(a:obj, k)
	        call EvalMember(a:obj[k], v)
            endif
	    let k += 1
        endfor
    else
	if s:has_element(a:obj, a:path)
            let a:obj[a:path] = eval(a:obj[a:path])
        endif
    endif
endfunction


function! Apply(target, onargs, args) abort
    call EvalMember(a:args, a:onargs)
    return call(function(a:target), a:args)
endfunction


function! ProjectRoot()
    return v:lua._trampouline("my.project", "project-root")
endfunction


" lua require("bootstrap.main").setup()
" lua require("bootstrap.main").runlisp()
" lua require("bootstrap.main").finalize()
lua require("bootstrap").setup()

""" init.vim ends here
