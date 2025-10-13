(local s (require "my.simple"))


(local kmap vim.api.nvim_buf_set_keymap)
(local handler "my.lsp.handlers")


(local keymap
  {:n {"<C-]>" :jump-definition
       "<M-]>" :jump-declaration
       :<leader>gi :jump-implementation
       :<leader>gt :jump-type-definition

       "[e" :diagnostic-prev
       "]e" :diagnostic-next

       :<leader>d :preview-definition

       :<leader>a :code-action
       :<leader>r :rename
       :<leader>f :format-line
       :<leader>F :format-buffer

       :<leader>sf :symbol-find
       :<leader>sr :symbol-references
       :<leader>sd :symbol-in-document
       :<leader>sw :symbol-in-workspace

       :<leader>q :line-diagnostic
       :<C-K> :signature-help
       :<leader>h :hover}
   :v {:<leader>a :range-code-action
       :<leader>f :format-region
       :<leader>F :format-region}})



(fn configure-diagnostic []
  (tset vim.lsp.callbacks "textDocument/publishDiagnostics"
        (vim.lsp.with vim.lsp.diagnostic.on_publish_diagnostics
                      {:underline true
                       :virtual_text true
                       :signs true
                       :update_in_insert false})))


(fn autocmd [bufnr event fun]
  (if (> bufnr 0)
    (string.format
      "autocmd %s <buffer=%d> lua _T('my.lsp.handlers', %q)"
      event bufnr fun)
    (string.format
      "autocmd %s <buffer> lua _T('my.lsp.handlers', %q)"
      event fun)))


(local highlight-command
  (table.concat ["augroup lsp_document_highlight"
                 "autocmd! * <buffer>"
                 (autocmd 0 :CursorHold :show-document-highlight)
                 (autocmd 0 :CursorHoldI :show-document-highlight)
                 (autocmd 0 :CursorMoved :clear-document-highlight)
                 "augroup END"]
   "\n"))


(fn init-highlight [bufnr]
  (vim.api.nvim_exec highlight-command false))


(fn default-buffer-config [client buf]
  (vim.api.nvim_buf_set_option 0 "omnifunc" "v:lua.vim.lsp.omnifunc")
  (init-highlight))


(local get-clients (or vim.lsp.get_clients vim.lsp.get_active_clients))


(fn on-attach [client buf]
  (let [clients (get-clients {:bufnr buf})]
    (when (and (= (length clients) 1)
               (= (. clients 1) client))
      (default-buffer-config client buf))))


(fn restart []
  (vim.lsp.stop_client (get-clients)))


(fn load-capabilities [name]
  (local f (io.open (vim.fs.joinpath _G.STDPATH.state
                                     "my"
                                     (.. "lsp-cap-" name ".json"))
                    "r"))
  (when f
    (local (data err) (f:read "*all")) 
    (f:close)
    (when err (error err))
    (vim.json.decode data)))



(fn setup []
  (each [mode keys (pairs keymap)]
    (each [key action (pairs keys)]
      (vim.keymap.set mode key
                      #(_T "my.lsp.handlers" action)
                      {:desc (.. "my.lsp.handlers::" action)})))
  (case (load-capabilities "cmp")
    cap (vim.lsp.config :* cap)))


{: on-attach 
 : restart 
 : setup} 

;;; lsp ends here
