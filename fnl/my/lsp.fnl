(module my.lsp
  {require {s my.simple}})


(def- kmap vim.api.nvim_buf_set_keymap)


(defn format-region []
  (vim.lsp.buf.range_formatting {} (s.point-min) (s.point-max)))


(def keymap
  {:gd "<cmd>lua vim.lsp.buf.declaration()<CR>"
   "<C-]>" "<cmd>lua vim.lsp.buf.definition()<CR>"
   :1gD "<cmd>lua vim.lsp.buf.type_definition()<CR>"
   :gD "<cmd>lua vim.lsp.buf.implementation()<CR>"
   :K "<cmd>lua vim.lsp.buf.hover()<CR>"
   :<C-K> "<cmd>lua vim.lsp.buf.signature_help()<CR>"
   :gr "<cmd>lua vim.lsp.buf.references()<CR>"
   :g0 "<cmd>lua vim.lsp.buf.document_symbol()<CR>"
   :gW "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>"})



(defn- quickfix-diagnostics [err method result client-id]
  (when (and result result.diagnostics)
    (each [_ v (ipairs result.diagnostics)]
      (tset v :bufnr client-id)
      (tset v :lnum (+ v.range.start.line 1))
      (tset v :col (+ v.range.character 1))
      (tset v :text v.message))
    (vim.lsp.util.set_qflist result.diagnostics)))



(defn enable-quickfix []
  (let [method "textDocument/publishDiagnostics"
        default-callback (. vim.lsp.callbacks method)]
    (tset vim.lsp.callbacks method
          (fn [err method result client-id]
            (default-callback err method result client-id)
            (quickfix-diagnostics err method result client-id)))))


(defn on-attach []
  (each [key action (pairs keymap)]
    (kmap 0 :n key action {:silent true :noremap true}))
  (kmap 0 :v :<localleader>f
        "<cmd>lua _trampouline('my.lsp', 'format-region')<CR>" {}))


(defn setup [])
