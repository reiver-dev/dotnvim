(module my.keybind
  {require {s my.simple}})


(defn setup []
  ;; Disable middle mouse paste
  (let [keys ["<MiddleMouse>" "<2-MiddleMouse>"
              "<3-MiddleMouse>" "<4-MiddleMouse>"]]
    (each [_ key (ipairs keys)]
      (s.kmap-global :ni key :<Nop>)))

  (when (= (vim.fn.has "win32") 1)
    (s.kmap-global :n :<C-z> :<Nop>))

  ;; Disable highlight
  (s.kmap-global :nv :<C-h> :<cmd>nohlsearch<cr>)

  ;; Copy-paste
  (s.kmap-global :i :<S-Insert> :<C-R>+)
  (s.kmap-global :nv :<S-Insert> "\"+P")
  (s.kmap-global :nv :<C-Insert> "\"+y")

  ;; Insert mode movement
  (s.kmap-global :i :<C-p> :<Up>)
  (s.kmap-global :i :<C-n> :<Down>)
  (s.kmap-global :i :<C-f> :<Right>)
  (s.kmap-global :i :<C-b> :<Left>)

  (s.kmap-global :i :<C-a> :<Home>)
  (s.kmap-global :i :<C-e> :<End>)

  (s.kmap-global :i :<M-f> :<S-Right>)
  (s.kmap-global :i :<M-b> :<S-Left>)

  ;; delete-char
  (s.kmap-global :i :<C-d> :<Del>)
  ;; backward-delete-char
  (s.kmap-global :i :<C-h> :<BS>)

  ;; kill-line
  (s.kmap-global :i :<C-k> :<C-\><C-o>D)
  (s.kmap-global :i :<C-DEL> :<C-\><C-o>D)
  (s.kmap-global :i :<C-BS> :<C-\><C-o>d0)
  (s.kmap-global :i :<M-k> :<End><C-u>)

  ;; forward-delete-word
  (s.kmap-global :i :<M-d> :<C-\><C-o>dw)
  (s.kmap-global :i :<M-DEL> :<C-\><C-o>dw)

  ;; backward-delete-word
  (s.kmap-global :i :<M-h> :<C-\><C-o>db)
  (s.kmap-global :i :<M-BS> :<C-\><C-o>db)

  ;; Switch to related buffer
  (s.kmap-global :n :<leader><leader> :<C-^>)

  ;; Additional wincmd key
  (s.kmap-global :n :<C-x><C-w> :<C-w>)

  ;; kill-buffer
  (s.kmap-global :n :<C-x>k
                 "<cmd>lua _T('my.simple', 'kill-current-buffer')<CR>")
  ;; kill-buffer-closing-window
  (s.kmap-global :n :<C-x><C-k>
                 "<cmd>confirm bdelete<CR>"))
