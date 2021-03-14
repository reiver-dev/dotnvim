(module my.ui
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def
    {:name "devicons"
     :url "kyazdani42/nvim-web-devicons"
     :opt true})
  (pkg.def
    {:name "galaxyline"
     :url "glepnir/galaxyline.nvim"
     :branch "main"
     :init (fn []
             (pkg.add "devicons")
             (pkg.add "galaxyline")
             (_T "nvim-web-devicons" "setup")
             (require "my.ui.galaxyline"))}))
    
