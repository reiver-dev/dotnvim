(module my.lang.cpp
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def
    {:name "lsp-cxx-highlight"
     :url "jackguo380/vim-lsp-cxx-highlight"
     :kind "opt"}))
