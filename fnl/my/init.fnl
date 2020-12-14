;;; My

(module my)


(def- modules 
  ["my.log"
   "my.bufreg"
   "my.options"
   "my.dirlocal"
   "my.tasks"
   "my.terminal"
   "my.editing"
   "my.vcs"
   "my.project"
   "my.lsp"
   "my.treesitter"
   "my.keybind"
   "my.commands"
   "my.lang.cpp"
   "my.pack.fzf"])


(defn setup [] 
  (each [_ mod (ipairs modules)]
    (_T mod "setup")))

;;; my.fnl ends here
