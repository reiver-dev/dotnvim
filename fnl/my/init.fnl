;;; My

(module my)


(def- modules 
  ["my.log"
   "my.bufreg"
   "my.options"
   "my.packer"
   "my.dirlocal"
   "my.terminal"
   "my.indent"
   "my.editing"
   "my.vcs"
   "my.theme"
   "my.directory"
   "my.project"
   "my.lsp"
   "my.keybind"
   "my.commands"
   "my.repl"
   "my.lang"
   "my.pack"
   "my.checkers"])


(defn setup []
  (set vim.g.loaded_matchit 1)
  (set vim.g.loaded_matchparen 1) 
  (each [_ mod (ipairs modules)]
    (_T mod "setup")))

;;; my.fnl ends here
