(fn setup []
  (_T :my.lsp.capabilities :update
      ((. (require "cmp_nvim_lsp") :default_capabilities))))

{: setup}
