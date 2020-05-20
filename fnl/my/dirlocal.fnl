(module my.dirlocal)


(defn- slurp [path]
  "Read the file into a string."
  (match (io.open path "r")
    (nil msg) nil
    f (let [content (f:read "*all")]
        (f:close)
        content)))


(defn- parent [dir]
  "Parent of a directory or nil."
  (let [candidate (vim.fn.fnamemodify dir ":h")]
    (when (and (not= dir candidate)
               (vim.fn.isdirectory candidate))
      candidate)))


(defn- parents [dir]
  "All parents of a directory."
  (var result [])
  (var dir (parent dir))
  (while dir
    (table.insert result 1 dir)
    (set dir (parent dir)))
  result)


(defn- file-readable? [path]
  "Is the file readable?"
  (= 1 (vim.fn.filereadable path)))


(defn- eval [script-dir script-file target-dir target-file]
  (match (pcall slurp script-file)
    (true text)
    (let [eval (. (require "aniseed.fennel") :eval)
          view (. (require "aniseed.view") :serialise)
          expand vim.fn.expand
          buffer (expand "<abuf>")
          file (expand "<afile>")
          options {:self-file script-file
                   :self-dir script-dir
                   :buffer buffer
                   :target-file target-file
                   :target-dir target-dir
                   :target-match file}]
      (match
        (pcall 
          eval
          text
          {:env (setmetatable {:_A  options :view view}
                              {:__index _G})})
        (false err) (print "dir-locals eval failed: " err)))
    (false err) (print "dir-locals read failed:" err)))


(defn execute []
  "Iterate over all directories from the root to the cwd.
  For every .lnvim.fnl, compile it to .lvim.lua (if required) and execute it.
  If a .lua is found without a .fnl, delete the .lua to clean up."
  (let [target (vim.fn.expand "<amatch>")
        target-name (vim.fn.fnamemodify target ":p:t")]
    (when (not (= target-name ".lnvim.fnl"))
      (let [cwd (vim.fn.fnamemodify target ":h")
            dirs (parents cwd)]
        (table.insert dirs cwd)
        (each [_ dir (ipairs dirs)]
          (let [src (.. dir "/.lnvim.fnl")]
            (when (file-readable? src)
              (eval dir src cwd target))))))))



(defn setup []
  (let [addhook (. (require "bootstrap.hook") :on :bufread)]
    (addhook ".*" execute)))

