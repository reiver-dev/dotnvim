(local b (require "my.bufreg"))
(local p (require "my.pathsep"))
(local w (require "my.fswalk"))
(local fs (require "my.filesystem"))

(local runmodule-template
  "import sys,runpy;sys.path.pop(0);runpy.run_module(%q,run_name='__main__')")


(fn environment [bufnr]
  (b.get-local bufnr :python :environment))


(local iswin (vim.startswith (. (vim.loop.os_uname) :version) "Windows"))
(local exetail (if iswin "python" "bin/python"))


(fn executable [bufnr]
  (or (b.get-local bufnr :python :executable)
      (let [venv (environment bufnr)]
        (when venv (p.join venv exetail)))
      "python"))


(fn table-append [tbl value]
  (when (~= nil value)
    (match (type value)
      :table (each [_ el (ipairs value)]
               (table.insert tbl el)) 
      :string (table.insert tbl value)
      :number (table.insert tbl (tostring value)))))


(fn join [...]
  (let [result []
        n (select :# ...)]
    (for [i 1 n]
      (let [el (select i ...)]
        (table-append result el)))
    result))


(fn run-module-arg [modname]
  (string.format runmodule-template modname))


(fn module-command [bufnr modname ...]
  (join (executable bufnr) "-c" (run-module-arg modname) ...))


(fn strip [path]
  (when path
    (let [result (path:gsub "^%s*(.-)%s*$" "%1")] 
      result)))


(fn maybe-slurp [path]
  (-?> path
       (fs.slurp)
       (strip)))


(fn discover-markers [path]
  (let [(files dirs) (w.gather path
                               ["setup.cfg" "pyproject.toml" "mypy.ini"
                                ".virtual_env" ".conda_prefix"]
                               [".venv"])]
    {: files : dirs}))


(fn ensure-markers [bufnr force]
  (var markers (b.get-local bufnr :python :markers))
  (when (not markers)
    (set markers (discover-markers (b.get-local bufnr :directory)))
    (b.set-local bufnr :python :markers markers))
  markers)


(fn initialize []
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


(local autocmd
  "augroup my_lang_python
  autocmd!
  autocmd FileType python lua _T('my.lang.python', 'initialize')
  augroup END")


(fn enable-venv-search []
  (vim.api.nvim_exec autocmd false))


(fn update-executable [repldef command]
  (let [repldef (vim.deepcopy repldef)
        newcommand []]
    (each [_ arg (ipairs command)]
      (table.insert newcommand arg))
    (each [i arg (ipairs repldef.command)]
      (when (~= i 1)
        (table.insert newcommand arg)))
    (set repldef.command newcommand)
    repldef))
  

(fn repl-python [bufnr]
  (let [iron (require "iron")
        repldef (update-executable
                  (. (require "iron.fts.python") :python)
                  [(executable (or bufnr 0))])]
    (iron.ll.create_new_repl :python repldef)))


(fn repl-ipython [bufnr]
  (let [iron (require "iron")
        repldef (update-executable
                  (. (require "iron.fts.python") :ipython)
                  (module-command (or bufnr 0) "IPython"))]
    (iron.ll.create_new_repl :python repldef)))


(fn setup []
  (enable-venv-search))


{: environment
 : executable 
 : run-module-arg 
 : module-command 
 : discover-markers 
 : ensure-markers 
 : initialize 
 : update-executable 
 : repl-python 
 : repl-ipython 
 : setup} 
