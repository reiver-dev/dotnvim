(module my.keybind
  {require {s my.simple}})


(defn setup []
  ;; Disable middle mouse paste
  (let [keys ["<MiddleMouse>" "<2-MiddleMouse>"
              "<3-MiddleMouse>" "<4-MiddleMouse>"]]
    (each [_ key (ipairs keys)]
      (s.kmap-global :ni key :<Nop>)))

  ;; Disable highlight
  (s.kmap-global :nv :<C-h> :<cmd>nohlsearch<cr>)

  ;; Copy-paste
  (s.kmap-global :i :<S-Insert> :<C-R>+)
  (s.kmap-global :nv :<S-Insert> "\"+p")
  (s.kmap-global :nv :<C-Insert> "\"+y")

  ;; Switch to related buffer
  (s.kmap-global :n :<leader><leader> :<C-^>)

  ;; Kill buffer
  (s.kmap-global :n :<C-x>k
                 "<cmd>lua _T('my.simple', 'kill-current-buffer')<CR>")
  (s.kmap-global :n :<C-x><C-k>
                 "<cmd>confirm bdelete<CR>"))
