(module my.treesitter
  {require {pkg bootstrap.pkgmanager}})


(defn- treesitter-setup [opts]
  (let [ts (require "nvim-treesitter.configs")]
    (ts.setup opts)))


(defn- configure []
  (treesitter-setup
    {:highlight {:enable true
                 :disable [:css]}
     :rainbow {:enable true}}))


(defn- packages []
  (pkg.def
    {:name "nvim-treesitter"
     :url "nvim-treesitter/nvim-treesitter"
     :init configure})
  (pkg.def
    {:name "nvim-treesitter-playground"
     :url "nvim-treesitter/playground"})
  (pkg.def
    {:name "nvim-treesitter-rainbow"
     :url "p00f/nvim-ts-rainbow"}))


(defn setup []
  (packages))
