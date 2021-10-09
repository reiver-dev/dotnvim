(module my.pack.tree)

(def- config
  {:disable_netrw false
   :hijack_netrw false})


(defn setup []
  (local tree (require "nvim-tree"))
  (tree.setup config))

