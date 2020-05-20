;;; My

(module my
  {require {lsp my.lsp
            dirlocal my.dirlocal}})

(defn setup [] 
  (lsp.setup)
  (dirlocal.setup))


;;; my.fnl ends here

