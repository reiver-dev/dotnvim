(module my.pack.cmp-lsp)

(defn setup []
  (_T :my.lsp.capabilities :update-with
      (. (require "cmp_nvim_lsp") :update_capabilities)))
