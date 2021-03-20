(module my.editing
  {require {s my.simple}})


(defn macro-every-line []
  (s.message "macro-every-line @" (vim.fn.getcmdline))
  (vim.api.nvim_exec
    (.. ":'<,'>normal @" (vim.fn.nr2char (vim.fn.getchar)))
    false))


(defn- define-command []
  (s.kmap-global :x "@" ":<C-u>call v:lua._T('my.editing', 'macro-every-line')<CR>"
                 :noremap))


(defn setup []
  (define-command))
