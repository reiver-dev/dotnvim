(local libnames
  {"Darwin" "libparinfer_rust.dylib"
   "Linux" "libparinfer_rust.so"
   "Unix" "libparinfer_rust.so"
   "Windows" "parinfer_rust.dll"
   "Windows_NT" "parinfer_rust.dll"})


(fn filetypes []
  [:clojure :scheme :list :racket :hy :fennel :janet :carp :wast])


(fn guess-libname []
  (var name (. libnames (. (vim.loop.os_uname) :sysname)))
  (when (not name)
    (if (= 1 (vim.fn.has "macunix"))
      (set name (. libnames :Darwin))
      (if (= 1 (vim.fn.has "unix"))
        (set name (. libnames :Unix))
        (if (= 1 (vim.fn.has "win32"))
          (set name (. libnames :Windows))
          (error "Parinfer failed to detect lib name")))))
  name)


(fn guess-libpath []
  (let [root (?. _G :packer_plugins :parinfer :path)]
    (when (and root (not= root ""))
      (let [name (guess-libname)]
        (table.concat [root "target/release" name] "/")))))


(fn start [command cwd]
  (let [bufnr (vim.api.nvim_create_buf true true)
        opts {:cwd cwd
              :on_exit (fn [jobid data event]
                         (vim.notify (string.format "Parinfer build exited: %d" data)))}]
    (vim.cmd (string.format ":vertical botright sbuffer %d" bufnr))
    (vim.fn.termopen command opts)))


(fn keep-window-finalize [oldwin ok ...]
  (vim.api.nvim_set_current_win oldwin)
  (when (not ok) (error ...))
  ...)


(fn keep-window [func ...]
  (let [curwin (vim.api.nvim_get_current_win)]
    (keep-window-finalize curwin (pcall func ...))))


(fn compile-library [plugin]
  (let [plugin (or plugin (?. _G :packer_plugins :parinfer))
        path (when plugin (or plugin.path plugin.install_path))]
    (vim.notify "Building parinfer lib")
    (keep-window start ["cargo" "build" "--release"] path)))


(fn setup []
  (let [libpath (guess-libpath)]
    (if (and libpath (= 1 (vim.fn.filereadable libpath)))
      (do
        (set vim.g.parinfer_enabled 1)
        (set vim.g.parinfer_dylib_path libpath))
      (do
        (set vim.g.parinfer_enabled 0)))))


{: filetypes 
 : guess-libname 
 : guess-libpath 
 : compile-library 
 : setup} 
