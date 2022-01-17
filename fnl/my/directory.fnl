(local b (require "my.bufreg"))

(local hook {})

(fn add-hook [name fun]
  (tset hook name fun))


(fn remove-hook [name]
  (tset hook name nil))


(fn call-hook [bufnr directory]
  (each [name fun (pairs hook)]
    (fun bufnr directory)))


(local normalize
  (if (= "\\" (package.config:sub 1 1))
    (fn [path] (string.gsub path "\\" "/"))
    (fn [path] path)))


(fn getcwd []
  (normalize (vim.fn.getcwd)))


(fn current-buffer-dir []
  "Find directory path for current buffer."
  (normalize (vim.fn.expand "%:p:h" 1)))


(fn empty? [str]
  "Check if STR string is nil or empty."
  (or (= nil str) (= "" str)))


(fn non-empty? [str]
  "Check if string exists and has characters."
  (and str (~= "" str)))


(fn directory? [path]
  "Check if PATH is existing directory."
  (if (non-empty? path)
    (let [(res msg code) (vim.loop.fs_stat path)]
      (and res (= (. res :type) "directory")))
    false))



(local autocmd
  "augroup projectile
  autocmd!
  autocmd VimEnter,BufNew,BufNewFile,BufReadPre * lua _T('my.directory', 'on-file-open')
  autocmd BufEnter * lua _T('my.directory', 'on-file-enter')
  autocmd BufWritePost * lua _T('my.directory', 'on-file-write')
  autocmd BufFilePost * lua _T('my.directory', 'on-file-rename')
  augroup END
  ")


(fn getbufvar [bufnr name]
  "Get buffer-local variable for BUFNR buffer by variable NAME."
  (match (pcall
           (fn []
             (vim.api.nvim_buf_get_var (or bufnr 0) name)))
    (true res) res
    _ ""))


(fn setbufvar [bufnr name value]
  "Assign buffer-local variable for BUFNR buffer by variable NAME to VALUE."
  (vim.api.nvim_buf_set_var (or bufnr 0) name value))


(fn set-default-directory [bufnr path]
  (b.set-local bufnr :directory path)
  (setbufvar bufnr :default_directory path))
  

(fn default-directory [bufnr]
  "Provide directory path for BUFNR buffer."
  (let [dd (b.get-local bufnr :directory)]
    (if dd
      dd
      (getbufvar bufnr :default_directory))))


(fn fire-user-event [bufnr event]
  "Execute autocmd user event for BUFNR buffer by EVENT name."
  (when (vim.fn.exists (string.format "#User#%s" event))
    (let [cmd (string.format "doautocmd <nomodeline> User %s" event)]
      (vim.api.nvim_buf_call bufnr (fn [] (vim.cmd cmd))))))


(fn fire-default-directory-updated [bufnr dir]
  "Execute autocmd DefaultDirectory for BUFNR buffer."
  (call-hook bufnr dir)
  (fire-user-event bufnr "DefaultDirectory"))


(fn apply-default-directory [bufnr]
  "Attempt to update default-directory for BUFNR buffer."
  (let [dd (default-directory bufnr)]
    (vim.api.nvim_buf_call
      bufnr #(let [dir (or (current-buffer-dir) (getcwd))]
               (set-default-directory bufnr dir)
               (when (~= dir dd)
                 (fire-default-directory-updated bufnr dir))))))


(fn force-default-directory [bufnr directory]
  "Make default-directory for BUFNR buffern to become DIRECTORY."
  (let [dd (default-directory bufnr)]
    (vim.api.nvim_buf_call
      bufnr (fn []
              (set-default-directory bufnr directory)
              (when (not= directory dd)
                (fire-default-directory-updated bufnr directory))))))


(fn on-file-enter []
  "Ensure local current directory is default-directory for current buffer."
  (when (empty? vim.bo.buftype)
    (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
          dd (default-directory bufnr)
          cwd (getcwd)]
      (when (and (not= dd cwd) (directory? dd))
        (vim.cmd (.. "lcd " dd))))))


(fn on-file-open []
  "Update default-directory for current buffer.
  Happens when buffer is not special and is loaded
  and buffer's file has not changed."
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (when (and (empty? (vim.api.nvim_buf_get_option bufnr :buftype))
               (vim.api.nvim_buf_is_loaded bufnr))
      (let [file (normalize (vim.fn.expand "<afile>:p"))
            oldfile (b.get-local bufnr :file)]
        (when (or (= oldfile nil) (not= file oldfile))
          (b.set-local bufnr :file file)
          (apply-default-directory bufnr))))))


(fn on-file-write []
  (on-file-open)
  (on-file-enter))


(fn on-file-rename []
  (on-file-open)
  (on-file-enter))


(fn setup []
  (vim.api.nvim_exec autocmd false))


{: setup
 : on-file-enter
 : on-file-open
 : on-file-write
 : on-file-rename
 : force-default-directory
 : default-directory
 : add-hook
 : remove-hook}
