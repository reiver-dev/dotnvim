(local v (require "my.vararg"))
(local s (require "my.strutil"))

(local argpack v.pack)
(local argunpack v.unpack)


(fn remove-tabs [text]
  (let [result (string.gsub text "\t" "    ")]
    result))


(fn message-1 [write ...]
  (let [ln (select :# ...)]
    (when (> ln 0)
      (write (remove-tabs (tostring (select 1 ...))))
      (for [i 2 ln]
        (write " ")
        (write (remove-tabs (tostring (select i ...))))))
    (write "\n")))


(fn message-safe [write ...]
  (if (vim.in_fast_event)
    (vim.schedule
      (let [args (argpack ...)]
        (fn [] (message-1 write (argunpack args)))))
    (message-1 write ...)))


(fn message [...]
  (message-safe vim.api.nvim_out_write ...))


(fn errmsg [...]
  (message-safe vim.api.nvim_err_write ...))


(local empty-preview-template
  (.. "silent! pedit! +setlocal"
      "\\ buftype=nofile"
      "\\ nobuflisted"
      "\\ noswapfile"
      "\\ nonumber"
      "\\ nowrap"
      "\\ filetype=%s"
      " %s"))


(fn verbose [command]
  (let [output (vim.api.nvim_exec command true)]
    (vim.cmd (string.format empty-preview-template :text "Verbose"))
    (vim.cmd "wincmd P")
    (let [bufnr (vim.api.nvim_get_current_buf)]
      (vim.api.nvim_paste output 0 -1)
      (vim.api.nvim_buf_set_keymap bufnr :n "q" ":bd<CR>" {:noremap true}))))


(fn expandvar [text]
  (s.expandvar text os.getenv))


(fn find-pos-1 [predicate next tbl idx]
  (let [(nidx val) (next tbl idx)]
    (when nidx
      (if (predicate val)
        nidx
        (find-pos-1 predicate next tbl nidx)))))


(fn find-pos [predicate tbl]
  (find-pos-1 predicate (ipairs tbl)))


(fn find-key [predicate tbl]
  (find-pos-1 predicate (pairs tbl)))


(fn loaded-buffers []
  (let [tbl []
        buffers (vim.api.nvim_list_bufs)]
    (var i 1)
    (each [_ b (ipairs buffers)]
      (when (vim.api.nvim_buf_is_loaded b)
        (tset tbl i b)
        (set i (+ i 1))))
    tbl))


(fn other-buffer [bufnr]
  (let [bufnr (or bufnr (vim.api.nvim_get_current_buf))
        altbufnr (vim.fn.bufnr "#")]
    (if (and (> altbufnr 0)
             (vim.fn.buflisted altbufnr)
             (vim.api.nvim_buf_is_loaded altbufnr))
      altbufnr
      (let [buffers (loaded-buffers)
            buflen (length buffers)]
        (when (> buflen 1)
          (let [pos (find-pos #(= $1 bufnr) buffers)]
            (if pos
              (. buffers (let [prevpos (- pos 1)]
                           (if (not= prevpos 0) prevpos buflen)))
              bufnr)))))))


(fn buffer-number [bufnr]
  (if (and (~= nil bufnr) (> 0 bufnr))
     bufnr
     (vim.api.nvim_get_current_buf)))


(fn buffer-modified? [bufnr]
  (vim.api.nvim_buf_get_option bufnr :modified))


(fn create-scratch-buffer []
  (let [buf (vim.api.nvim_create_buf false false)]
    (vim.api.nvim_buf_set_option buf :swapfile false)
    (vim.api.nvim_buf_set_option buf :bufhidden :wipe)
    (vim.api.nvim_buf_set_option buf :buftype "")
    buf))


(fn prepare-delete-buffer [bufnr force]
  (if (not (buffer-modified? bufnr))
    (do
      (when (vim.api.nvim_buf_get_option bufnr :buflisted)
        (vim.api.nvim_buf_set_option bufnr :bufhidden "hide"))
      true)
    (if force
      (do
        (when (vim.api.nvim_buf_get_option bufnr :buflisted)
          (vim.api.nvim_buf_set_option bufnr :bufhidden "hide"))
        true)
      (match
        (vim.fn.confirm "Save changes?" "&Yes\n&No\n&Cancel" 0 "Question")
        0 (error "E89: No write since last change for buffer")
        1 (do
            (vim.api.nvim_buf_call bufnr (fn [] (vim.cmd "write")))
            (vim.api.nvim_buf_set_option bufnr :bufhidden "hide")
            true)
        2 (do
            (vim.api.nvim_buf_set_option bufnr :bufhidden "hide")
            true)
        3 false))))


(fn kill-buffer [bufnr force]
  (let [bufnr (buffer-number bufnr)]
    (when (prepare-delete-buffer bufnr force)
      (let [otherbufnr (let [buf (other-buffer bufnr)]
                         (if (and buf (not= buf bufnr))
                           buf
                           (create-scratch-buffer)))
            windows (vim.api.nvim_list_wins)]
        (each [i win (ipairs windows)]
          (let [winbufnr (vim.api.nvim_win_get_buf win)]
            (when (= winbufnr bufnr)
              (vim.api.nvim_win_set_buf win otherbufnr)))))
      (when (vim.api.nvim_buf_is_loaded bufnr)
        (if (vim.api.nvim_buf_get_option bufnr :buflisted)
          (vim.cmd (.. "bdelete! " bufnr))
          (vim.cmd (.. "bwipeout! " bufnr)))))))


(fn kill-current-buffer [force]
  (kill-buffer (vim.api.nvim_get_current_buf) force))


(fn var-set [name value]
  (vim.api.nvim_buf_set_var 0 name value))


(fn var-get [name]
  (vim.api.nvim_buf_get_var 0 name))


(fn option-set [name value]
  (vim.fn.setbufvar "" (.. "&" name)
                    (match value
                      (true) 1
                      (false) 0
                      (any) any)))


(fn option-get [name]
  (vim.fn.getbufvar "" (.. "&" name)))


(fn option-list []
  {:buf (vim.fn.getbufvar "" "&")
   :win (vim.fn.getbufvar 0 "&")})


(fn var-list []
  {:buf (vim.fn.getbufvar "" "")
   :win (vim.fn.getbufvar 0 "")})


(fn command-list []
  {:global (vim.api.nvim_get_commands {})
   :local (vim.api.nvim_buf_get_commands 0 {})})


(fn kmap-flags [...]
  (let [res {}]
    (for [i 1 (select :# ...)]
      (tset res (select i ...) true))
    (if res.remap
      (set res.remap nil)
      (set res.noremap true))
    res))


(fn chars-iter [str idx]
  (let [nidx (+ idx 1)]
    (when (<= nidx (str:len))
      (values nidx (str:sub nidx nidx)))))


(fn chars [str]
  (values chars-iter str 0))


(fn kmap [modes key action ...]
  (each [_ mode (chars modes)]
    (vim.api.nvim_buf_set_keymap 0 mode key action (kmap-flags ...))))


(fn kmap-global [modes key action ...]
  (each [_ mode (chars modes)]
    (vim.api.nvim_set_keymap mode key action (kmap-flags ...))))


(fn getpos [name]
  (let [pos (vim.fn.getpos name)]
    [(. pos 2) (- (. pos 3) 1)]))


(fn line []
  (vim.fn.line "."))


(fn column []
  (- (vim.fn.col ".") 1))


(fn eol []
  (- (vim.fn.col "$") 1))


(fn point []
  (getpos "."))


(fn visual-point []
  (let [(sb se) (unpack (getpos "v"))
        (eb ee) (unpack (getpos "."))]
    {:min [(math.min sb eb)
           (math.min se ee)]
     :max [(math.max sb eb)
           (math.max se ee)]}))


(fn line-begin []
  [(line) 0])


(fn line-end []
  [(line) (eol)])


(fn operator-begin []
  (vim.api.nvim_buf_get_mark 0 "["))


(fn operator-end []
  (vim.api.nvim_buf_get_mark 0 "]"))


(fn visual-begin []
  (vim.api.nvim_buf_get_mark 0 "<"))


(fn visual-end []
  (vim.api.nvim_buf_get_mark 0 ">"))


{: message-1 
 : message 
 : errmsg 
 : verbose 
 : expandvar 
 : find-pos 
 : find-key 
 : loaded-buffers 
 : other-buffer 
 : buffer-number 
 : buffer-modified? 
 : create-scratch-buffer 
 : kill-buffer 
 : kill-current-buffer 
 : var-set 
 : var-get 
 : option-set 
 : option-get 
 : option-list 
 : var-list 
 : command-list 
 : kmap 
 : kmap-global 
 : getpos 
 : line 
 : column 
 : eol 
 : point 
 : visual-point 
 : line-begin 
 : line-end 
 : operator-begin 
 : operator-end 
 : visual-begin 
 : visual-end} 
