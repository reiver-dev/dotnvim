(module my.filetree
  {require {pkg bootstrap.pkgmanager}})


(defn- packages []
  (pkg.def
    {:name "tree"
     :url "kyazdani42/nvim-tree.lua"
     :init (fn []
             (set vim.g.nvim_tree_hijack_netrw 0)
             (set vim.g.nvim_tree_disable_netrw 0))})) 


(defn setup []
  (packages))

