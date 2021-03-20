(module my.lang.python
  {require {b my.bufreg
            p my.pathsep
            w my.fswalk
            fs my.filesystem}})


(def- runmodule-template
  "import sys,runpy;sys.path.pop(0);runpy.run_module(%q,run_name='__main__')")


(defn environment [bufnr]
  (b.get-local bufnr :python :environment))


(def- iswin (vim.startswith (. (vim.loop.os_uname) :version) "Windows"))
(def- exetail (if iswin "python" "bin/python"))


(defn executable [bufnr]
  (or (b.get-local bufnr :python :executable)
      (let [venv (environment bufnr)]
        (when venv (p.join venv exetail)))
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


(defn- strip [path]
  (when path
    (let [result (path:gsub "^%s*(.-)%s*$" "%1")] 
      result)))


(defn- maybe-slurp [path]
  (-?> path
       (fs.slurp)
       (strip)))


(defn discover-markers [path]
  (let [(files dirs) (w.gather path
                               ["setup.cfg" "pyproject.toml" "mypy.ini"
                                ".virtual_env" ".conda_prefix"]
                               [".venv"])]
    {: files : dirs}))


(defn ensure-markers [bufnr force]
  (var markers (b.get-local bufnr :python :markers))
  (when (not markers)
    (set markers (discover-markers (b.get-local bufnr :directory)))
    (b.set-local bufnr :python :markers markers))
  markers)


(defn initialize []
  (let [dir (vim.fn.expand "<afile>:p:h")
        bufnr (tonumber (vim.fn.expand "<abuf>"))
        markers (ensure-markers bufnr)]
    (when (not (b.get-local bufnr :python :environment))
      (let [env (or (-?> markers
                        (. :files)
                        (. :.virtual_env)
                        (. 1)
                        (maybe-slurp))
                    (-?> markers
                        (. :dirs)
                        (. :.venv)
                        (. 1)))]
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
