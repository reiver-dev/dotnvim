(module my.repl
  {require {pkg bootstrap.pkgmanager}})


(defn- packages []
  (pkg.def {:name "iron.nvim"
            :url "hkupty/iron.nvim"}))
            

(defn setup []
  (packages))
