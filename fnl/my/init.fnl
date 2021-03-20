;;; My

(module my)


(def- modules 
  ["my.log"
   "my.bufreg"
   "my.options"
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
  (let [packer (require "packer")]
    (packer.startup (fn [...] (_T :my.packages :setup ...))))
  (each [_ mod (ipairs modules)]
    (_T mod "setup")))

;;; my.fnl ends here
