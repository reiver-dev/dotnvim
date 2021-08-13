(module my.dirlocal)


(defn- slurp [path]
  "Read the file from PATH into a string."
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


(defn- evaluate [script-file options]
  "Execute fennel SCRIPT-FILE with OPTIONS table as `_A` global variable."
  (match (pcall slurp script-file)
    (true text)
    (let [eval (. (require "fennel") :eval)
          view (require "fennel.view")]
      (match
        (pcall eval text {:env (setmetatable {:_A  options :view view}
                                             {:__index _G})})
        (false err) (print "dir-locals `" script-file "` eval failed: " err)))
    (false err) (print "dir-locals `" script-file "` read failed:" err)))


(defn- valid? [tbl]
  "Is TBL non-empty table."
  (and (~= nil tbl)
       (~= nil (next tbl))))


(defn- target-options []
  (let [target-file (vim.fn.expand "<afile>")
        target-match (vim.fn.expand "<amatch>")
        target-dir (vim.fn.fnamemodify target-match ":h")
        target-name (vim.fn.fnamemodify target-match ":p:t")
        target-bufnr (vim.fn.expand "<abuf>")]
    {:dir target-dir
     :file target-file
     :name target-name
     :match target-match
     :bufnr target-bufnr}))


(defn prepare []
  "Collect every `.lnvim.fnl` over all parent directories starting from root.
  Result is stored in buffer-local variable `dirlocal_pending`."
  (let [target (target-options)
        pending []]
    (when (not (= target.name ".lnvim.fnl"))
      (let [dirs (parents target.dir)]
        (table.insert dirs target.dir)
        (each [_ dir (ipairs dirs)]
          (let [src (.. dir "/.lnvim.fnl")]
            (when (file-readable? src)
              (table.insert pending
                            {:self {:dir dir :file src}
                             :target target}))))))
    (when (valid? pending)
      (vim.api.nvim_buf_set_var target.bufnr :dirlocal_pending pending))))  


(defn execute []
  "Evaluate script definitions stored in buffer-local `dirlocal_pending`."
  (let [pending vim.b.dirlocal_pending]
    (when (valid? pending)
      (set vim.b.dirlocal_pending [])
      (each [_ entry (ipairs pending)]
        (evaluate entry.self.file entry))))) 


(def- command
  "augroup dirlocal
  autocmd!
  autocmd BufReadPost * call v:lua._trampouline('my.dirlocal', 'prepare')
  autocmd BufWinEnter * call v:lua._trampouline('my.dirlocal', 'execute')
  augroup END")


(defn setup []
  (vim.api.nvim_exec command nil))
