;;; lsp.handlers

(local p (require "my.point"))

(local base vim.lsp.buf)
(local base-diag vim.diagnostic)


(fn telescope [name fallback]
  (local (has ts) (pcall require :telescope.builtin))
  (if
    has
    ((. ts name))
    (not= nil fallback)
    ((. base name))))


(fn jump-declaration []
  (base.declaration))


(fn jump-definition []
  (telescope :lsp_definitions :definition))


(fn jump-implementation []
  (telescope :lsp_implementations :implementation))


(fn jump-type-definition []
  (base.type_definition))


(fn preview-definition [])


(fn diagnostic-prev []
  (base-diag.goto_prev))


(fn diagnostic-next []
  (base-diag.goto_next))


(fn code-action []
  (base.code_action))


(fn range-code-action []
  (base.range_code_action))


(fn rename []
  (base.rename))


(fn format-line []
  (base.format {:range {:start [(p.line-begin)]
                        :end [(p.line-end)]}}))


(fn format-region []
  (let [(bl bc el ec) (p.visual-point)]
    (base.format {:range {:start [bl bc]
                          :end [el ec]}})))


(fn format-buffer []
  (base.format))


(fn symbol-find [])


(fn symbol-references []
  (telescope :lsp_references :references))


(fn symbol-in-document []
  (telescope :lsp_document_symbols :document_symbol))


(fn symbol-in-workspace []
  (telescope :lsp_workspace_symbols :workspace_symbol))


(fn line-diagnostic []
  (base-diag.open_float))


(fn signature-help []
  (base.signature_help))


(fn hover []
  (base.hover))


(fn show-document-highlight []
  (base.document_highlight))


(fn clear-document-highlight []
  (base.clear_references))


{: jump-declaration 
 : jump-definition 
 : jump-implementation 
 : jump-type-definition 
 : preview-definition 
 : diagnostic-prev 
 : diagnostic-next 
 : code-action 
 : range-code-action 
 : rename 
 : format-line 
 : format-region 
 : format-buffer 
 : symbol-find 
 : symbol-references 
 : symbol-in-document 
 : symbol-in-workspace 
 : line-diagnostic 
 : signature-help 
 : hover 
 : show-document-highlight 
 : clear-document-highlight} 

;;; lsp.handlers ends here
