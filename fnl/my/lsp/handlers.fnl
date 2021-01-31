;;; lsp.handlers

(module my.lsp.handlers
  {require {s my.simple}})


(defn- modcall [mod name]
  (let [(ok mod) (pcall (fn [] (require mod)))]
    (when ok
      ((. mod name)))))
 
 
(defn- saga [submod name]
  (modcall (.. "lspsaga." submod) name))


(defn- telescope [name]
  (modcall "telescope.builtin" name))
 

(defn jump-declaration []
  (vim.lsp.buf.declaration))


(defn jump-definition []
  (vim.lsp.buf.definition))


(defn jump-implementation []
  (vim.lsp.buf.implementation))


(defn jump-type-definition []
  (vim.lsp.buf.type_definition))


(defn preview-definition []
  (saga :provider :preview_definition))
  

(defn diagnostic-prev []
  (saga :diagnostic :lsp_jump_diagnostic_prev))
  

(defn diagnostic-next []
  (saga :diagnostic :lsp_jump_diagnostic_next))


(defn open-terminal []
  (saga :floaterm :open_float_terminal))


(defn close-terminal []
  (saga :floaterm :close_float_terminal))


(defn code-action []
  (saga :codeaction :code_action))


(defn range-code-action []
  (saga :codeaction :range_code_action))


(defn rename []
  (saga :rename :rename))


(defn format-line []
  (vim.lsp.buf.range_formatting {} (s.line-begin) (s.line-end)))
  

(defn format-region []
  (let [p (s.visual-point)]
    (vim.lsp.buf.range_formatting {} p.min p.max)))


(defn format-buffer []
  (vim.lsp.buf.formatting))


(defn symbol-find []
  (saga :provider :lsp_finder))


(defn symbol-references []
  (telescope :lsp_references))


(defn symbol-in-document []
  (telescope :lsp_document_symbols))


(defn symbol-in-workspace []
  (telescope :lsp_workspace_symbols)) 


(defn line-diagnostic []
  (vim.lsp.diagnostic.show_line_diagnostics))


(defn signature-help []
  (saga :signaturehelp :signature_help))


(defn hover []
  (vim.lsp.buf.hover))


(defn show-document-highlight []
  (vim.lsp.buf.document_highlight))


(defn clear-document-highlight []
  (vim.lsp.buf.clear_references))


;;; lsp.handlers ends here
