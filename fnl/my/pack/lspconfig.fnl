;;; nvim-lspconfig configuration


(fn on-attach [...]
  ((or (?. _G.package.loaded "my.lsp" "on-attach")
       (. (require "my.lsp") "on-attach"))
   ...))


(fn update-default-config [...]
  (local lspconfig-util (require "lspconfig.util"))
  (set lspconfig-util.default_config
       (vim.tbl_extend :force lspconfig-util.default_config ...)))



(fn update-default-capabilities [caps]
  (update-default-config {:capabilities caps}))


(fn setup []
  (local caps (require "my.lsp.capabilities"))
  (update-default-config {:on_attach on-attach :capabilities (caps.get)})
  (caps.hook :lspconfig-default update-default-capabilities))


{: setup}
