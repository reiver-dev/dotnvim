(module my.pack.parinfer)


(def- libnames
  {"Darwin" "libparinfer_rust.dylib"
   "Linux" "libparinfer_rust.so"
   "Unix" "libparinfer_rust.so"
   "Windows" "parinfer_rust.dll"
   "Windows_NT" "parinfer_rust.dll"})


(defn filetypes []
  [:clojure :scheme :list :racket :hy :fennel :janet :carp :wast])
  

(defn guess-libname []
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


(defn guess-libpath []
  (let [root (?. _G :packer_plugins :parinfer :path)]
    (when (and root (not= root ""))
      (let [name (guess-libname)]
        (table.concat [root "target/release" name] "/")))))


(defn- start [command cwd]
  (let [bufnr (vim.api.nvim_create_buf true true)
        opts {:cwd cwd
              :on_exit (fn [jobid data event]
                         (vim.notify (string.format "Parinfer build exited: %d" data)))}]
    (vim.cmd (string.format ":vertical botright sbuffer %d" bufnr))
    (vim.fn.termopen command opts)))
  

(defn compile-library [plugin]
  (let [plugin (or plugin (?. _G :packer_plugins :parinfer))
        path (when plugin (or plugin.path plugin.install_path))]
    (vim.notify "Building paringer lib")
    (start ["cargo" "build" "--release"] path)))
      

(defn setup []
  (let [libpath (guess-libpath)]
    (if (and libpath (= 1 (vim.fn.filereadable libpath)))
      (do
        (set vim.g.parinfer_enabled 1)
        (set vim.g.parinfer_dylib_path libpath))
      (do
        (set vim.g.parinfer_enabled 0)))))
      
