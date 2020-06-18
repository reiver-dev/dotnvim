(module my.vcs
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def
    {:name :signify
     :url "mhinz/vim-signify"}))
