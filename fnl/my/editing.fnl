(module my.editing
  {require {pkg bootstrap.pkgmanager
            s my.simple}})


(defn macro-every-line []
  (s.message "macro-every-line @" (vim.fn.getcmdline))
  (vim.api.nvim_exec
    (.. ":'<,'>normal @" (vim.fn.nr2char (vim.fn.getchar)))
    false))


(defn- define-command []
  (s.kmap-global :x "@" ":<C-u>call v:lua._T('my.editing', 'macro-every-line')<CR>"
                 :noremap))


(defn setup []
  (define-command)
  (pkg.def 
    {:name :table-mode
     :url "dhruvasagar/vim-table-mode"})
  (pkg.def
    {:name :tabular
     :url "godlygeek/tabular"})
  (pkg.def
    {:name :easy-align
     :url "junegunn/vim-easy-align"})
  (pkg.def
    {:name :surround
     :url "tpope/vim-surround"})
  (pkg.def
    {:name :visual-multi
     :url "mg979/vim-visual-multi"}))
