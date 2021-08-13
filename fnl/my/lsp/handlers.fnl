;;; lsp.handlers

(module my.lsp.handlers
  {require {p my.point}})


(defn- modcall [mod name]
  (let [(ok mod) (pcall (fn [] (require mod)))]
    (when ok
      ((. mod name)))))


(def base vim.lsp.buf)
(def base-diag vim.lsp.diagnostic)


(defn- saga [submod name]
  (modcall (.. "lspsaga." submod) name))


(defn- telescope [name]
  (modcall "telescope.builtin" name))


(defn jump-declaration []
  (base.declaration))


(defn jump-definition []
  (base.definition))


(defn jump-implementation []
  (base.implementation))


(defn jump-type-definition []
  (base.type_definition))


(defn preview-definition [])


(defn diagnostic-prev []
  (base-diag.goto_prev))


(defn diagnostic-next []
  (base-diag.goto_next))


(defn open-terminal []
  (saga :floaterm :open_float_terminal))


(defn close-terminal []
  (saga :floaterm :close_float_terminal))


(defn code-action []
  (base.code_action))


(defn range-code-action []
  (base.range_code_action))


(defn rename []
  (base.rename))


(defn format-line []
  (base.range_formatting {} [(p.line-begin)] [(p.line-end)]))


(defn format-region []
  (let [pos (p.visual-point)]
    (base.range_formatting {} pos.min pos.max)))


(defn format-buffer []
  (base.formatting))


(defn symbol-find [])


(defn symbol-references []
  (telescope :lsp_references))


(defn symbol-in-document []
  (telescope :lsp_document_symbols))


(defn symbol-in-workspace []
  (telescope :lsp_workspace_symbols))


(defn line-diagnostic []
  (base-diag.show_line_diagnostics))


(defn signature-help []
  (base.signature_help))


(defn hover []
  (base.hover))


(defn show-document-highlight []
  (base.document_highlight))


(defn clear-document-highlight []
  (base.clear_references))


;;; lsp.handlers ends here
