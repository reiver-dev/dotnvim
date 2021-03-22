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


(defn- packer-config []
  (let [join (. (require "packer.util") :join_paths)
        iswin (= (. (vim.loop.os_uname) :sysname) "Windows_NT")
        root (if iswin
               (join (vim.fn.stdpath "config") "pack")
               (join (vim.fn.stdpath "data") "site" "pack"))]
	{:package_root root}))


(defn- init-packages []
  (let [packer (require "packer")
	spec {}]
    (tset spec 1 (fn [...] (_T :my.packages :setup ...)))
    (tset spec :config (packer-config))
    (packer.startup spec)))


(defn setup []
  (init-packages)
  (each [_ mod (ipairs modules)]
    (_T mod "setup")))

;;; my.fnl ends here
