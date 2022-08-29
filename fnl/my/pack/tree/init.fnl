(local config
  {:disable_netrw false
   :hijack_netrw false})


(fn setup []
  (local tree (require "nvim-tree"))
  (tree.setup config))


{: setup}
