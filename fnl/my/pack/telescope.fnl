(module my.pack.telescope)


(defn setup []
  (_T :telescope :load_extension :my)
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>Telescope buffers<CR>" {:noremap true}))
  
