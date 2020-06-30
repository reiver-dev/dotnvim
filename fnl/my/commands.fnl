(module my.commands
  {require {s my.simple}})


(def- verbose-command
  (.. "command! -range=-1 -nargs=1 -complete=command" 
      " Verbose :lua _T('my.simple', 'verbose', <q-args>)"))


(defn- define-verbose-command []
  (vim.cmd verbose-command))
    

(defn setup []
  (define-verbose-command))
