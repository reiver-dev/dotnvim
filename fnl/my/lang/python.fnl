(module my.lang.python
  {require {b my.bufreg
            p my.pathsep
            w my.fswalk
            fs my.filesystem}})


(def- runmodule-template
  "import sys,runpy;sys.path.pop(0);runpy.run_module(%q,run_name='__main__')")


(defn environment [bufnr]
  (b.get-local bufnr :python :environment))


(defn executable [bufnr]
  (or (b.get-local bufnr :python :exec)
      (let [venv (environment bufnr)]
        (when venv (p.join venv "bin/python")))
      "python"))


(defn- table-append [tbl value]
  (when (~= nil value)
    (match (type value)
      :table (each [_ el (ipairs value)]
               (table.insert tbl el)) 
      :string (table.insert tbl value)
      :number (table.insert tbl (tostring value)))))


(defn- join [...]
  (let [result []
        n (select :# ...)]
    (for [i 1 n]
      (let [el (select i ...)]
        (table-append result el)))
    result))


(defn module-command [bufnr modname ...]
  (join (executable bufnr) "-c" (runmodule-template:format modname) ...))


(defn maybe-slurp [path]
  (when path (fs.slurp path)))


(defn python-env [path]
  (let [(f d) (w.gather path [".virtual_env" ".conda_prefix"] [".venv"])]
    {:VIRTUAL_ENV (or (maybe-slurp (. f :.virtual_env))
                      (. d :.venv))
     :CONDA_PREFIX (maybe-slurp (. f :.conda_prefix))}))


(defn initialize []
  (let [dir (vim.fn.expand "<afile>:p:h")
        bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (let [{:VIRTUAL_ENV env} (python-env dir)]
      (when env
        (b.set-local bufnr :python :environment env)))))


(def- autocmd
  "augroup my_lang_python
  autocmd!
  autocmd FileType python lua _T('my.lang.python', 'initialize')
  augroup END")


(defn- enable-venv-search []
  (vim.api.nvim_exec autocmd false))


(defn update-executable [repldef command]
  (let [repldef (vim.deepcopy repldef)
        newcommand []]
    (each [_ arg (ipairs command)]
      (table.insert newcommand arg))
    (each [i arg (ipairs repldef.command)]
      (when (~= i 1)
        (table.insert newcommand arg)))
    (set repldef.command newcommand)
    repldef))
  

(defn repl-python [bufnr]
  (let [iron (require "iron")
        repldef (update-executable
                  (. (require "iron.fts.python") :python)
                  [(executable (or bufnr 0))])]
    (iron.ll.create_new_repl :python repldef)))


(defn repl-ipython [bufnr]
  (let [iron (require "iron")
        repldef (update-executable
                  (. (require "iron.fts.python") :ipython)
                  (module-command (or bufnr 0) "IPython"))]
    (iron.ll.create_new_repl :python repldef)))


(defn setup []
  (enable-venv-search))
