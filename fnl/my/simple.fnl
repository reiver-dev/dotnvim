(module my.simple)

(defn set-local-var [name value]
  (vim.api.nvim_buf_set_var 0 name value))


(defn get-local-var [name]
  (vim.api.nvim_buf_get_var 0 name))


(defn set-local-option [name value]
  (vim.fn.setbufvar "" (.. "&" name)
                    (match value
                      (true) 1
                      (false) 0
                      (any) any)))


(defn get-local-option [name]
  (vim.fn.getbufvar "" (.. "&" name)))


(defn list-local-options []
  {:buf (vim.fn.getbufvar "" "&")
   :win (vim.fn.getbufvar 0 "&")})


(defn list-local-var []
  {:buf (vim.fn.getbufvar "" "")
   :win (vim.fn.getbufvar 0 "")})


(defn list-commands []
  {:global (vim.api.nvim_get_commands {})
   :local (vim.api.nvim_buf_get_commands 0 {})})


(defn kmap [mode key action ...]
  (let [opts {}]
    (each [_i opt (ipairs [...])]
      (tset opts opt true))
    (vim.api.nvim_buf_set_keymap 0 mode key action opts)))


(defn point []
  (vim.api.nvim_buf_get_mark 0 "."))


(defn visual-point []
  (let [(sb se) (unpack (vim.api.nvim_buf_get_mark 0 "v"))
        (eb ee) (unpack (vim.api.nvim_buf_get_mark 0 "."))]
    {:min [(math.min sb eb)
           (math.min se ee)]
     :max [(math.max sb eb)
           (math.max se ee)]}))


(defn line []
  (vim.fn.line "."))


(defn column []
  (- (vim.fn.col ".") 1))


(defn eol []
  (- (vim.fn.col "$") 1))


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
