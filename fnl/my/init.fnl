;;; My

(module my
  {require {lsp my.lsp
            dirlocal my.dirlocal
            tasks my.tasks
            editing my.editing
            proj my.project
            vcs my.vcs}})


(defn setup [] 
  (lsp.setup)
  (dirlocal.setup)
  (tasks.setup)
  (editing.setup)
  (vcs.setup)
  (_trampouline "my.lang.cpp" "setup"))


;;; my.fnl ends here
