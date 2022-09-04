(local verbose-command
  (.. "command! -range=-1 -nargs=1 -complete=command" 
      " Verbose :lua _T('my.simple', 'verbose', <q-args>)"))


(fn define-verbose-command []
  (vim.cmd verbose-command))
    

(fn setup []
  (define-verbose-command))


{: setup}
