(module my.range)


(defn range-len [start stop step]
  (if (or (and (> step 0) (< start stop))
          (and (< step 0) (< stop start)))
    (math.ceil (/ (math.abs (- stop start))
                  (math.abs step)))
    0))


(defn range-iter [state idx]
  (when (< idx (. state 1))
    (values (+ idx 1)
            (+ (* (. state 3) idx) (. state 2)))))
    

(defn range [start stop step]
  (values range-iter [(range-len start stop step) start step] 0))
