(local arg-dot ".")
(local arg-eol "$")
(local arg-v "v")


(local call vim.call)


(fn getpos [args]
  (let [pos (call :getpos args)]
    (values (. pos 2) (- (. pos 3) 1))))


(fn line []
  (call :line arg-dot))


(fn column []
  (- (call :col arg-dot) 1))


(fn eol []
  (- (call :col arg-eol) 1))


(fn current []
  (getpos arg-dot))


(fn visual-point []
  (let [(sb se) (getpos arg-v)
        (eb ee) (getpos arg-dot)]
    (values (math.min sb eb)
            (math.min se ee)
            (math.max sb eb)
            (math.max se ee))))


(fn line-begin []
  (values (line) 0))


(fn line-end []
  (values (line) (eol)))


(fn operator-begin []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "[")]
    (values b e)))


(fn operator-end []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "]")]
    (values b e)))


(fn range-begin []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "<")]
    (values b e)))


(fn range-end []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 ">")]
    (values b e)))


{: line : column
 : eol
 : current
 : visual-point
 : line-begin : line-end
 : operator-begin : operator-end
 : range-begin : range-end}
