;; Neogen config

(fn setup []
  (_T :neogen :setup {:enabled true})
  (vim.keymap.set :n :<leader>nf
                  #(_T :neogen :generate)
                  {:desc "neogen::generate"}))


{: setup}
