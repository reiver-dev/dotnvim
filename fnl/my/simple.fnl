(module my.simple)


(defn point-min []
  (vim.api.nvim_buf_get_mark 0 "["))


(defn point-max []
  (vim.api.nvim_buf_get_mark 0 "]"))
