(module my.keybind
  {require {s my.simple}})


(defn setup []
  (s.kmap-global :n
                 :<C-h> :<cmd>nohlsearch<cr>
                 :noremap)
  (s.kmap-global :v
                 :<C-h> :<cmd>nohlsearch<cr>
                 :noremap)
  (s.kmap-global :n
                 :<leader><leader>
                 :<C-^>)
  (s.kmap-global :n
                 :<C-x>k "<cmd>lua _T('my.simple', 'kill-current-buffer')<CR>"
                 :noremap)
  (s.kmap-global :n
                 :<C-x><C-k> "<cmd>confirm bdelete<CR>"
                 :noremap))
