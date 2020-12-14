(module my.simple)


(defn str-join [sep ...]
  (table.concat [...] sep))


(defn message [...]
  (let [ln (select :# ...)
        write vim.api.nvim_out_write]
    (when (> ln 0)
      (write (tostring (select 1 ...)))
      (for [i 2 ln]
        (write " ")
        (write (tostring (select i ...)))))
    (write "\n")))


(def- empty-preview-template
  (.. "silent! pedit! +setlocal"
      "\\ buftype=nofile"
      "\\ nobuflisted"
      "\\ noswapfile"
      "\\ nonumber"
      "\\ nowrap"
      "\\ filetype=%s"
      " %s"))


(defn verbose [command]
  (let [output (vim.api.nvim_exec command true)]
    (vim.cmd (string.format empty-preview-template :text "Verbose"))
    (vim.cmd "wincmd P")
    (let [bufnr vim.api.nvim_get_cuttent_buf]
      (vim.api.nvim_paste output 0 -1)
      (vim.api.nvim_buf_set_keymap bufnr :n "q" ":bd<CR>" {:noremap true}))))


(defn- find-pos-1 [predicate next tbl idx]
  (let [(nidx val) (next tbl idx)]
    (when nidx
      (if (predicate val)
        nidx
        (find-pos-1 predicate next tbl nidx)))))


(defn find-pos [predicate tbl]
  (find-pos-1 predicate (ipairs tbl)))


(defn find-key [predicate tbl]
  (find-pos-1 predicate (pairs tbl)))


(defn loaded-buffers []
  (let [tbl []
        buffers (vim.api.nvim_list_bufs)]
    (var i 1)
    (each [_ b (ipairs buffers)]
      (when (vim.api.nvim_buf_is_loaded b)
        (tset tbl i b)
        (set i (+ i 1))))
    tbl))


(defn other-buffer [bufnr]
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


(defn buffer-number [bufnr]
  (if (and (~= nil bufnr) (> 0 bufnr))
     bufnr
     (vim.api.nvim_get_current_buf)))


(defn buffer-modified? [bufnr]
  (vim.api.nvim_buf_get_option bufnr :modified))



(defn create-scratch-buffer []
  (let [buf (vim.api.nvim_create_buf false false)]
    (vim.api.nvim_buf_set_option buf :swapfile false)
    (vim.api.nvim_buf_set_option buf :bufhidden :wipe)
    (vim.api.nvim_buf_set_option buf :buftype "")
    buf))


(defn- prepare-delete-buffer [bufnr force]
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


(defn kill-buffer [bufnr force]
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


(defn kill-current-buffer [force]
  (kill-buffer (vim.api.nvim_get_current_buf) force))


(defn var-set [name value]
  (vim.api.nvim_buf_set_var 0 name value))


(defn var-get [name]
  (vim.api.nvim_buf_get_var 0 name))


(defn option-set [name value]
  (vim.fn.setbufvar "" (.. "&" name)
                    (match value
                      (true) 1
                      (false) 0
                      (any) any)))


(defn option-get [name]
  (vim.fn.getbufvar "" (.. "&" name)))


(defn option-list []
  {:buf (vim.fn.getbufvar "" "&")
   :win (vim.fn.getbufvar 0 "&")})


(defn var-list []
  {:buf (vim.fn.getbufvar "" "")
   :win (vim.fn.getbufvar 0 "")})


(defn command-list []
  {:global (vim.api.nvim_get_commands {})
   :local (vim.api.nvim_buf_get_commands 0 {})})


(defn- flags [...]
  (let [res {}]
    (for [i 1 (select :# ...)]
      (tset res (select i ...) true))
    res))


(defn kmap [mode key action ...]
  (vim.api.nvim_buf_set_keymap 0 mode key action (flags ...)))


(defn kmap-global [mode key action ...]
  (vim.api.nvim_set_keymap mode key action (flags ...)))


(defn getpos [name]
  (let [pos (vim.fn.getpos name)]
    [(. pos 2) (- (. pos 3) 1)]))


(defn line []
  (vim.fn.line "."))


(defn column []
  (- (vim.fn.col ".") 1))


(defn eol []
  (- (vim.fn.col "$") 1))


(defn point []
  (getpos "."))


(defn visual-point []
  (let [(sb se) (unpack (getpos "v"))
        (eb ee) (unpack (getpos "."))]
    {:min [(math.min sb eb)
           (math.min se ee)]
     :max [(math.max sb eb)
           (math.max se ee)]}))


(defn line-begin []
  [(line) 0])


(defn line-end []
  [(line) (eol)])


(defn operator-begin []
  (vim.api.nvim_buf_get_mark 0 "["))


(defn operator-end []
  (vim.api.nvim_buf_get_mark 0 "]"))


(defn visual-begin []
  (vim.api.nvim_buf_get_mark 0 "<"))


(defn visual-end []
  (vim.api.nvim_buf_get_mark 0 ">"))
