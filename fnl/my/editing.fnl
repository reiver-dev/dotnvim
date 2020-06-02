(module my.editing
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def 
    {:name :table-mode
     :url "dhruvasagar/vim-table-mode"})
  (pkg.def
    {:name :easy-align
     :url "junegunn/vim-easy-align"})
  (pkg.def
    {:name :surround
     :url "tpope/vim-surround"})
  (pkg.def
    {:name :multiple-cursors
     :url "terryma/vim-multiple-cursors"}))
