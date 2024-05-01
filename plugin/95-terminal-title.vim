function! TerminalTitleEventHandler(d,k,v)
    call v:lua._T("my.terminal", "set-title", 0, a:v['new'])
endfunction

function! s:TerminalTitleSetupWatcher()
    silent! call dictwatcherdel(b:, 'term_title', 'TerminalTitleEventHandler')
    call v:lua._T("my.terminal", "set-title", 0, b:term_title)
    call dictwatcheradd(b:, 'term_title', 'TerminalTitleEventHandler')
endfunction

augroup my_terminal_title
autocmd!
autocmd TermOpen * call s:TerminalTitleSetupWatcher()
augroup END
