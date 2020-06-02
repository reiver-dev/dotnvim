;;; My

(module my
  {require {lsp my.lsp
            dirlocal my.dirlocal
            tasks my.tasks
            editing my.editing}})

(defn setup [] 
  (lsp.setup)
  (dirlocal.setup)
  (tasks.setup)
  (editing.setup))


;;; my.fnl ends here
