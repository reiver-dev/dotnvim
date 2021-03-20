(module my.pack.telescope)


(defn setup []
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>Telescope buffers<CR>" {:noremap true}))
  
