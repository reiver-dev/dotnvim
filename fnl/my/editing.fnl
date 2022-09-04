(local s (require "my.simple"))


(fn macro-every-line []
  (s.message "macro-every-line @" (vim.fn.getcmdline))
  (vim.api.nvim_exec
    (.. ":'<,'>normal @" (vim.fn.nr2char (vim.fn.getchar)))
    false))


(fn define-command []
  (s.kmap-global :x "@" ":<C-u>call v:lua._T('my.editing', 'macro-every-line')<CR>"
                 :noremap))


(fn setup []
  (define-command))


{: setup
 : macro-every-line}
