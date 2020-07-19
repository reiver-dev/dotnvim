(module my.util)


(defn- cycle-iter [state param a b c]
  (let [param (+ 1 (% param state.end))]
    (when (not= param state.begin)
      (values param (. state.table param)))))


(defn cycle [begin tbl]
  (if (<= begin 0)
    (ipairs tbl)
    (let [end (length tbl)
          begin (% begin end)]
      (values cycle-iter {:begin begin :end end :table tbl} begin))))


(defn- cycle-apply-impl [func begin end idx]
  (when (and (not= begin idx) (func idx))
    (cycle-apply-impl func begin end (+ 1 (% idx end)))))


(defn cycle-apply [func idx end]
  (if (<= idx 0)
    (when (and (< 0 end) (func 1) (< 1 end))
      (cycle-apply-impl func 1 end 2))
    (let [idx (% idx end)
          begin (if (not= idx 0) idx end)]
      (cycle-apply-impl func begin end (+ 1 (% idx end))))))
