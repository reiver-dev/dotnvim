(module my.theme
  {require {pkg bootstrap.pkgmanager}})


(defn setup []
  (pkg.def 
    {:name "colorbuddy"
     :url "tjdevries/colorbuddy.nvim"})
  (pkg.def
    {:name "modus-theme"
     :url "ishan9299/modus-theme-vim"})
  (pkg.def
    {:name "zephyr-theme"
     :url "glepnir/zephyr-nvim"
     :init (fn [] (require "zephyr"))})
  (pkg.def
    {:name "nvcode-theme"
     :url "ChristianChiarulli/nvcode-color-schemes.vim"}))
