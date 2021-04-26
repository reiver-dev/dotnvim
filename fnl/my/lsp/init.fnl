(module my.lsp
  {require {s my.simple}})


(def- kmap vim.api.nvim_buf_set_keymap)
(def- handler "my.lsp.handlers")


(defn- simplecall [mod fun]
  (string.format "<cmd>lua _T(%q, %q)<CR>" mod fun))


(defn- rangecall [mod fun]
  (string.format "<cmd>lua _T(%q, %q)<CR>" mod fun))


(defn- termcall [mod fun]
  (string.format "<C-\\><C-n>:lua _T(%q, %q)<CR>" mod fun))


(defn- F [fun]
  (simplecall handler fun))


(defn- R [fun]
  (rangecall handler fun))


(defn- T [fun]
  (termcall handler fun))


(def keymap
  {:gd "<cmd>lua vim.lsp.buf.declaration()<CR>"
   "<C-]>" "<cmd>lua vim.lsp.buf.definition()<CR>"
   :1gD "<cmd>lua vim.lsp.buf.type_definition()<CR>"
   :gD "<cmd>lua vim.lsp.buf.implementation()<CR>"
   :K "<cmd>lua vim.lsp.buf.hover()<CR>"
   :<C-K> "<cmd>lua vim.lsp.buf.signature_help()<CR>"
   :gr "<cmd>lua vim.lsp.buf.references()<CR>"
   :g0 "<cmd>lua vim.lsp.buf.document_symbol()<CR>"
   :gW "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>"
   :<leader>F "<cmd>lua vim.lsp.buf.formatting()<CR>"
   :<leader>f "<cmd>lua _trampouline('my.lsp', 'format-line')<CR>"
   :<leader>d "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>"})


(def- keymap-extra
  {:n {"<C-]>" (F :jump-definition)
       "<M-]>" (F :jump-declaration)
       :<leader>gi (F :jump-implementation)
       :<leader>gt (F :jump-type-definition)

       "[e" (F :diagnostic-prev)
       "]e" (F :diagnostic-next)

       :<leader>d (F :preview-definition)

       :<leader>a (F :code-action)
       :<leader>r (F :rename)
       :<leader>f (F :format-line)
       :<leader>F (F :format-buffer)

       :<leader>sf (F :symbol-find)
       :<leader>sr (F :symbol-references)
       :<leader>sd (F :symbol-in-document)
       :<leader>sw (F :symbol-in-workspace)

       :<leader>q (F :line-diagnostic)
       :<C-K> (F :signature-help)
       :K (F :hover)}
   :v {:<leader>a (R :range-code-action)
       :<leader>f (F :format-region)}})



(defn- configure-diagnostic []
  (tset vim.lsp.callbacks "textDocument/publishDiagnostics"
        (vim.lsp.with vim.lsp.diagnostic.on_publish_diagnostics
                      {:underline true
                       :virtual_text true
                       :signs true
                       :update_in_insert false})))


(defn- autocmd [bufnr event fun]
  (if (> bufnr 0)
    (string.format
      "autocmd %s <buffer=%d> lua _T('my.lsp.handlers', %q)"
      event bufnr fun)
    (string.format
      "autocmd %s <buffer> lua _T('my.lsp.handlers', %q)"
      event fun)))


(def- highlight-command
  (table.concat ["augroup lsp_document_highlight"
                 "autocmd! * <buffer>"
                 (autocmd 0 :CursorHold :show-document-highlight)
                 (autocmd 0 :CursorHoldI :show-document-highlight)
                 (autocmd 0 :CursorMoved :clear-document-highlight)
                 "augroup END"]
   "\n"))


(defn- init-highlight [bufnr]
  (vim.api.nvim_exec highlight-command false))


(defn- default-buffer-config [client buf]
  (vim.api.nvim_buf_set_option 0 "omnifunc" "v:lua.vim.lsp.omnifunc")
  (init-highlight))


(defn on-attach [client buf]
  (let [clients (vim.lsp.buf_get_clients buf)]
    (when (and (= (length clients) 1)
               (= (. clients 1) client))
      (default-buffer-config client buf))))


(defn restart []
  (vim.lsp.stop_client (vim.lsp.get_active_clients)))


(defn setup []
  (each [mode keys (pairs keymap-extra)]
    (each [key action (pairs keys)]
      (vim.api.nvim_set_keymap mode key action {:noremap true}))))

;;; lsp ends here
