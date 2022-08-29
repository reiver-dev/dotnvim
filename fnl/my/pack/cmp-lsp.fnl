(fn setup []
  (_T :my.lsp.capabilities :update-with
      (. (require "cmp_nvim_lsp") :update_capabilities)))

{: setup}
