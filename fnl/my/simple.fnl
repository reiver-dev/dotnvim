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
