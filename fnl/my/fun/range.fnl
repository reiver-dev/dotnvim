;;; Range iterators

(local abs math.abs)
(local ceil math.ceil)
(local floor math.floor)


(fn empty [state idx])


(fn range-len-inclusive [start stop step]
  (if (or (and (> step 0) (< start stop))
          (and (< step 0) (< stop start)))
    (floor (/ (abs (- stop start))
              (abs step)))
    0))


(fn range-len-exclusive [start stop step]
  (if (or (and (> step 0) (< start stop))
          (and (< step 0) (< stop start)))
    (ceil (/ (abs (- stop start))
             (abs step)))
    0))


(fn iter-range-inclusive [state idx]
  (when (<= idx (. state 1))
    (values (+ idx 1)
            (+ (* (. state 3) idx) (. state 2)))))


(fn iter-range-exclusive [state idx]
  (when (< idx (. state 1))
    (values (+ idx 1)
            (+ (* (. state 3) idx) (. state 2)))))


(fn range [start stop ?step]
  (let [step (or ?step 1)
        len (range-len-inclusive start stop step)]
    (if (< 0 len)
      (values iter-range-inclusive [len start step] 0)
      (values empty 0 0))))


(fn erange [start stop ?step]
  (let [step (or ?step 1)
        len (range-len-exclusive start stop step)]
    (if (< 0 len)
      (values iter-range-exclusive [len start step] 0)
      (values empty 0 0))))


(fn dup [x]
  (values x x))


(fn irange-iter-inc1 [state idx]
  (when (< idx state)
    (dup (+ idx 1))))


(fn irange-iter-inc [state idx]
  (local nidx (+ idx (. state 2)))
  (when (<= nidx (. state 1))
    (dup nidx)))


(fn irange-iter-dec1 [state idx]
  (when (> idx state)
    (dup (- idx 1))))


(fn irange-iter-dec [state idx]
  (local nidx (- idx (. state 2)))
  (when (>= nidx (. state 1))
    (dup nidx)))


(fn irange [start stop ?step]
  (match ?step
    nil (values irange-iter-inc1 stop (- start 1))
    1 (values irange-iter-inc1 stop (- start 1))
    -1 (values irange-iter-dec1 stop (+ start 1))
    0 (values empty 0 0)
    (x ? (< 0 x)) (values irange-iter-inc [stop x] (- start x))
    (x ? (> 0 x)) (values irange-iter-dec [stop (- x)] (- start x))))


{: range
 : erange
 : irange}
