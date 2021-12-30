;;; lsp.handlers

(module my.lsp.handlers
  {require {p my.point}})


(def- base vim.lsp.buf)
(def- base-diag vim.diagnostic)


(defn- telescope [name fallback]
  (local (has ts) (pcall require :telescope.builtin))
  (if
    has
    ((. ts name))
    (not= nil fallback)
    ((. base name))))


(defn jump-declaration []
  (base.declaration))


(defn jump-definition []
  (telescope :lsp_definitions :definition))


(defn jump-implementation []
  (telescope :lsp_implementations :implementation))


(defn jump-type-definition []
  (base.type_definition))


(defn preview-definition [])


(defn diagnostic-prev []
  (base-diag.goto_prev))


(defn diagnostic-next []
  (base-diag.goto_next))


(defn code-action []
  (base.code_action))


(defn range-code-action []
  (base.range_code_action))


(defn rename []
  (base.rename))


(defn format-line []
  (base.range_formatting {} [(p.line-begin)] [(p.line-end)]))


(defn format-region []
  (let [(bl bc el ec) (p.visual-point)]
    (base.range_formatting {} [bl bc] [el ec])))


(defn format-buffer []
  (base.formatting))


(defn symbol-find [])


(defn symbol-references []
  (telescope :lsp_references :references))


(defn symbol-in-document []
  (telescope :lsp_document_symbols :document_symbol))


(defn symbol-in-workspace []
  (telescope :lsp_workspace_symbols :workspace_symbol))


(defn line-diagnostic []
  (base-diag.open_float))


(defn signature-help []
  (base.signature_help))


(defn hover []
  (base.hover))


(defn show-document-highlight []
  (base.document_highlight))


(defn clear-document-highlight []
  (base.clear_references))


;;; lsp.handlers ends here
