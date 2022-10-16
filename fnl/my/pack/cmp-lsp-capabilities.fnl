(macro get-capabilities []
  ((. (require "cmp_nvim_lsp") :default_capabilities)))

(get-capabilities)
