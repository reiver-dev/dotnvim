(module my.treesitter)


(defn- treesitter-setup [opts]
  (let [ts (require "nvim-treesitter.configs")]
    (ts.setup opts)))


(defn setup []
  (vim.cmd "packadd nvim-treesitter")
  (treesitter-setup
    {:highlight {:enable :true}}))
