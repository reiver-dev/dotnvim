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
  (each [_ modname (ipairs modules)]
    (match (pcall require modname)
      (true mod) (match (pcall mod.setup)
                   (false err) (error
                                 (string.format
                                   "Fail at mod init %s:\n    %s" modname err)))
      (false err) (vim.notify
                    (string.format "Failed to load %s:\n    %s" modname err)
                    vim.log.levels.ERROR))))

;;; my.fnl ends here
