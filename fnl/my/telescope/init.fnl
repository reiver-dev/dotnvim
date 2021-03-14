(module my.telescope
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def
    {:name "telescope"
     :url "nvim-lua/telescope.nvim"
     :init (fn []
             ;; (vim.api.nvim_set_keymap
             ;;   :n "<C-x>f" "<cmd>Telescope file_browser<CR>" {:noremap true})
             (vim.api.nvim_set_keymap
               :n "<C-x>b" "<cmd>Telescope buffers<CR>" {:noremap true}))}))
             

            
