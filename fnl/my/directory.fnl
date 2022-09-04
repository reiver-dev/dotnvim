(local {: get-local : set-local} (require "my.bufreg"))

(local vim-getcwd vim.fn.getcwd)
(local vim-fnamemodify vim.fn.fnamemodify)
(local str-match string.match)
(local str-gsub string.gsub)

(local nvim_buf_get_option vim.api.nvim_buf_get_option)
(local nvim_buf_is_loaded vim.api.nvim_buf_is_loaded)
(local nvim_buf_get_var vim.api.nvim_buf_get_var)
(local nvim_buf_set_var vim.api.nvim_buf_set_var)
(local nvim_buf_call vim.api.nvim_buf_call)


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
    (fn [path] (str-gsub path "\\" "/"))
    (fn [path] path)))


(fn getcwd []
  (normalize (vim-getcwd)))


(fn fs-dirname [name]
  (vim.fs.dirname name))


(fn term-dirname [name]
  (-> name
      (str-match "^[a-z][a-z]+://(.+)//[0-9]+:")
      (vim-fnamemodify ":p")
      (normalize)))


(fn fugitive-dirname [name]
  (-> name
      (str-gsub "^fugitive://(.+)//.*$" "file://%1")
      (vim.uri_to_fname)
      (vim.fs.dirname)
      (normalize)))


(fn uri-dirname [name]
  (-> name
      (vim.uri_to_fname)
      (vim.fs.dirnamel)
      (normalize)))


(fn extract-dirname [name]
  (local scheme (str-match name "^[a-z][a-z]+:"))
  (if
    (not scheme) (fs-dirname name) 
    (= scheme "term:") (term-dirname name)
    (= scheme "fugitive:") (fugitive-dirname name)
    (uri-dirname name)))


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


(fn getbufvar [bufnr name]
  "Get buffer-local variable for BUFNR buffer by variable NAME."
  (match (pcall nvim_buf_get_var (or bufnr 0) name)
    (true res) res
    _ ""))


(fn setbufvar [bufnr name value]
  "Assign buffer-local variable for BUFNR buffer by variable NAME to VALUE."
  (nvim_buf_set_var (or bufnr 0) name value))


(fn set-default-directory [bufnr path]
  (set-local bufnr :directory path)
  (setbufvar bufnr :default_directory path))


(fn default-directory [bufnr]
  "Provide directory path for BUFNR buffer."
  (let [dd (get-local bufnr :directory)]
    (if dd
      dd
      (getbufvar bufnr :default_directory))))


(fn fire-user-event [bufnr event data]
  "Execute autocmd user event for BUFNR buffer by EVENT name."
  (vim.api.nvim_exec_autocmds
    "User" {:pattern event
            :modeline false
            :data data}))


(fn fire-default-directory-updated [bufnr new old]
  "Execute autocmd DefaultDirectory for BUFNR buffer."
  (call-hook bufnr new)
  (fire-user-event bufnr "DefaultDirectory" {:buf bufnr :new new :old old}))


(fn apply-default-directory [bufnr dirname]
  "Attempt to update default-directory for BUFNR buffer."
  (let [dd (default-directory bufnr)]
    (nvim_buf_call
      bufnr #(let [dir (or dirname (getcwd))]
               (set-default-directory bufnr dir)
               (when (~= dir dd)
                 (fire-default-directory-updated bufnr dir dd))))))


(fn force-default-directory [bufnr directory]
  "Make default-directory for BUFNR buffern to become DIRECTORY."
  (let [dd (default-directory bufnr)]
    (nvim_buf_call
      bufnr (fn []
              (set-default-directory bufnr directory)
              (when (not= directory dd)
                (fire-default-directory-updated bufnr directory))))))


(fn on-file-enter [opts]
  "Ensure local current directory is default-directory for current buffer."
  (local dd (default-directory opts.buf))
  (when dd
    (local cwd (getcwd))
    (when (and (not= dd cwd) (directory? dd))
      (vim.cmd.lcd dd))))


(fn on-file-open [opts]
  "Update default-directory for current buffer.
  Happens when buffer is not special and is loaded
  and buffer's file has not changed."
  (when (and opts
             (= "" (nvim_buf_get_option opts.buf :buftype))
             (nvim_buf_is_loaded opts.buf))
    (let [bufnr opts.buf
          file (normalize opts.match)
          oldfile (get-local bufnr :file)]
      (when (or (= oldfile nil) (not= file oldfile))
        (set-local bufnr :file file)
        (apply-default-directory bufnr (if (= "" file) nil
                                         (extract-dirname file)))))))


(fn on-file-write [opts]
  (on-file-open opts)
  (on-file-enter opts))


(fn on-file-rename [opts]
  (on-file-open opts)
  (on-file-enter opts))


(fn setup []
  (local g (vim.api.nvim_create_augroup :projectile {:clear true}))
  (local au vim.api.nvim_create_autocmd)
  (au [:VimEnter :BufNew :BufNewFile :BufReadPre]
      {:group g
       :callback on-file-open})
  (au :BufEnter
       {:group g
        :callback on-file-enter})
  (au :BufWritePost
      {:group g
       :callback on-file-write})
  (au :BufFilePost
      {:group g
       :callback on-file-rename}))


{: setup
 : on-file-enter
 : on-file-open
 : on-file-write
 : on-file-rename
 : force-default-directory
 : default-directory
 : add-hook
 : remove-hook}
