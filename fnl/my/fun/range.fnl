(module my.range)

(def- abs math.abs)
(def- ceil math.ceil)

(defn- empty [state idx])


(defn range-len [start stop step]
  (if (or (and (> step 0) (< start stop))
          (and (< step 0) (< stop start)))
    (ceil (/ (abs (- stop start))
             (abs step)))
    0))


(defn range-iter [state idx]
  (when (<= idx (. state 1))
    (values (+ idx 1)
            (+ (* (. state 3) idx) (. state 2)))))


(defn range [start stop ?step]
  (let [step (or ?step 1)
        len (range-len start stop step)]
    (if (< 0 len)
      (values range-iter [len start step] 0)
      empty)))


(defn- dup [x]
  (values x x))


(defn irange-iter-inc1 [state idx]
  (when (< idx state)
    (dup (+ idx 1))))


(defn irange-iter-inc [state idx]
  (when (< idx (. state 1))
    (dup (+ idx (. state 2)))))


(defn irange-iter-dec1 [state idx]
  (when (> idx state)
    (dup (- idx 1))))


(defn irange-iter-dec [state idx]
  (when (> idx (. state 1))
    (dup (- idx (. state 2)))))


(defn irange [start stop ?step]
  (match ?step
    nil (values irange-iter-inc1 stop (- start 1))
    1 (values irange-iter-inc1 stop (- start 1))
    -1 (values irange-iter-dec1 stop (+ start 1))
    0 (values empty 0 0)
    (x ? (< 0 x)) (values irange-iter-inc [stop x] (- start x))
    (x ? (> 0 x)) (values irange-iter-dec [stop (- x)] (- start x))))


(let [tbl [5 4 3 2 1]]
  (each [k v (range 1 (length tbl) 1)]
    (print k (. tbl v))))


(let [tbl [5 4 3 2 1]]
  (each [k (irange 1 (length tbl))]
    (print k)))
