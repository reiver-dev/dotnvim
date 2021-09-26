(module my.point)


(def- arg-dot ["."])
(def- arg-eol ["$"])
(def- arg-v ["v"])


(def- call vim.api.nvim_call_function)


(defn- getpos [args]
  (let [pos (call :getpos args)]
    (values (. pos 2) (- (. pos 3) 1))))


(defn line []
  (call :line arg-dot))


(defn column []
  (- (call :col arg-dot) 1))


(defn eol []
  (- (call :col arg-eol) 1))


(defn current []
  (getpos arg-dot))


(defn visual-point []
  (let [(sb se) (getpos arg-v)
        (eb ee) (getpos arg-dot)]
    (values (math.min sb eb)
            (math.min se ee)
            (math.max sb eb)
            (math.max se ee))))


(defn line-begin []
  (values (line) 0))


(defn line-end []
  (values (line) (eol)))


(defn operator-begin []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "[")]
    (values b e)))


(defn operator-end []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "]")]
    (values b e)))


(defn range-begin []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 "<")]
    (values b e)))


(defn range-end []
  (let [[b e] (vim.api.nvim_buf_get_mark 0 ">")]
    (values b e)))
