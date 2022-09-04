;;; My

(module my)


(def- modules
  ["my.bufreg"
   "my.options"
   "my.terminal"
   "my.indent"
   "my.editing"
   "my.vcs"
   "my.directory"
   "my.project"
   "my.lsp"
   "my.keybind"
   "my.commands"
   "my.lang"
   "my.pack"
   "my.checkers"
   "my.help"
   "my.scratch"])


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
