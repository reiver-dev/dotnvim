(module my.directory
  {require {b my.bufreg}})

(def- hook {})

(defn add-hook [name fun]
  (tset hook name fun))


(defn remove-hook [name]
  (tset hook name nil))


(defn call-hook [bufnr directory]
  (each [name fun (pairs hook)]
    (fun bufnr directory)))


(defn- current-buffer-dir []
  "Find directory path for current buffer."
  (vim.fn.expand "%:p:h" 1))


(defn- empty? [str]
  "Check if STR string is nil or empty."
  (or (= nil str) (= "" str)))


(defn- non-empty? [str]
  "Check if string exists and has characters."
  (and str (~= "" str)))


(defn- directory? [path]
  "Check if PATH is existing directory."
  (if (non-empty? path)
    (let [(res msg code) (vim.loop.fs_stat path)]
      (and res (= (. res :type) "directory")))
    false))


(def- autocmd
  "augroup projectile
  autocmd!
  autocmd VimEnter,BufNew,BufNewFile,BufReadPre * lua _T('my.directory', 'on-file-open')
  autocmd BufEnter * lua _T('my.directory', 'on-file-enter')
  autocmd BufWritePost * lua _T('my.directory', 'on-file-write')
  autocmd FileType netrw lua _T('my.directory', 'on-netrw-open')
  augroup END
  ")


(defn- getbufvar [bufnr name]
  "Get buffer-local variable for BUFNR buffer by variable NAME."
  (match (pcall
           (fn []
             (vim.api.nvim_buf_get_var (or bufnr 0) name)))
    (true res) res
    _ ""))
  

(defn- setbufvar [bufnr name value]
  "Assign buffer-local variable for BUFNR buffer by variable NAME to VALUE."
  (vim.api.nvim_buf_set_var (or bufnr 0) name value))


(defn- set-default-directory [bufnr path]
  (b.set-local bufnr :directory path)
  (setbufvar bufnr :default_directory path))
  

(defn default-directory [bufnr]
  "Provide directory path for BUFNR buffer."
  (let [dd (b.get-local bufnr :directory)]
    (if dd
      dd
      (getbufvar bufnr :default_directory))))


(defn- fire-user-event [bufnr event]
  "Execute autocmd user event for BUFNR buffer by EVENT name."
  (when (vim.fn.exists (string.format "#User#%s" event))
    (let [cmd (string.format "doautocmd <nomodeline> User %s" event)]
      (vim.api.nvim_buf_call bufnr (fn [] (vim.cmd cmd))))))


(defn- fire-default-directory-updated [bufnr dir]
  "Execute autocmd DefaultDirectory for BUFNR buffer."
  (call-hook bufnr dir)
  (fire-user-event bufnr "DefaultDirectory"))


(defn- apply-default-directory [bufnr]
  "Attempt to update default-directory for BUFNR buffer."
  (let [dd (default-directory bufnr)]
    (vim.api.nvim_buf_call 
      bufnr
      (fn []
        (let [dir (or (current-buffer-dir) (vim.fn.getcwd))]
          (when (~= dir dd)
            (set-default-directory bufnr dir)
            (fire-default-directory-updated bufnr dir)))))))


(defn on-file-open []
  "Update default-directory for current buffer.
  Happens when buffer is not special and is loaded
  and buffer's file has not changed."
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (when (and (empty? (vim.api.nvim_buf_get_option bufnr :buftype))
               (vim.api.nvim_buf_is_loaded bufnr))
      (let [file (vim.fn.expand "<afile>:p")
            oldfile (b.get-local bufnr :file)]
        (when (or (= oldfile nil) (~= file oldfile))
          (b.set-local bufnr :file file)
          (apply-default-directory bufnr))))))


(defn on-file-write []
  (on-file-open))


(defn on-netrw-open []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (when (and (= "nofile" (vim.api.nvim_buf_get_option bufnr :buftype))
               (= "netrw" (vim.api.nvim_buf_get_option bufnr :filetype))
               (vim.api.nvim_buf_is_loaded bufnr))
      (let [file (vim.fn.expand "<afile>:p")
            oldfile (b.get-local bufnr :file)]
        (when (or (= oldfile nil) (~= file oldfile))
          (b.set-local bufnr :file file)
          (apply-default-directory bufnr))))))


(defn on-file-enter []
  "Ensure local current directory is default-directory for current buffer."
  (when (empty? vim.bo.buftype)
    (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
          dd (default-directory bufnr)]
      (when (directory? dd)
        (vim.cmd (.. "lcd " dd))))))


(defn setup []
  (vim.api.nvim_exec autocmd false))
