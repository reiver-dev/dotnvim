(module my.fun)

(def- ceil math.ceil)
(def- abs math.abs)

(macro call-1 [argument]
  `((. state 1) ,argument))


(macro make-iter [n argument]
  (let [n1 n
        n2 (+ n 1)]
    `((. state  ,n1) (. state ,n2) ,argument)))


(macro iter-1 [argument]
  `(make-iter 1 ,argument))


(macro iter-2 [argument]
  `(make-iter 2 ,argument))


(macro nn [value]
  `(~= ,value nil))


(macro v1 [value]
  `(. ,value 1))

(macro v2 [value]
  `(. ,value 2))

(macro v3 [value]
  `(. ,value 3))


(defn- empty [state idx])


(defn- wrap [iter state idx]
  [iter state idx]) 


(defn- values-group-2 [i idx ...]
  (when (nn idx)
    (values [i idx] ...)))


(defn- values-group-3 [a b idx ...]
  (when (nn idx)
    (values [a b idx] ...)))


;; Take N

(defn- iter-take-impl [state idx ...]
  (when (nn idx)
    (state)
    (values-group-2 (+ (v1 idx) 1)
                    (iter-2 (v2 idx)))))


(defn- iter-take [state idx]
  (when (< (v1 idx) (v2 state))
    (iter-take-impl state idx (iter-2 (v2 idx)))))


(defn take [n iter state idx]
  (values iter-take [n iter state] [0 idx]))


;; Take while

(defn- iter-take-while-impl-1 [state idx ...]
  (when (and (nn idx) (call-1 ...))
    (values idx ...)))


(defn- iter-take-while-impl [state idx]
  (iter-take-while-impl-1 state (iter-2 idx)))


(defn take-while [predicate iter state idx]
  (values iter-take-while-impl [predicate iter state] idx))
    

;; Enumerate

(defn- iter-enumerate-impl [nidx state idx ...]
  (when (nn idx)
    (tset nidx 1 (+ (v1 nidx) 1))
    (tset nidx 2 idx)
    (values nidx state)))


(defn iter-enumerate [state idx]
  (iter-enumerate-impl idx state (iter-1 (v2 idx))))


(defn enumerate [iter state idx]
  (values iter-enumerate [iter state] [1 idx]))


;; Filter

(defn- iter-filter-impl-1 [state idx ...]
  (when (nn idx)
    (if (call-1 ...)
      (values idx ...)
      (iter-filter-impl-1 state (iter-2 idx)))))


(defn- iter-filter-impl [state idx]
  (iter-filter-impl-1 state (iter-2 idx)))


(defn filter [predicate iter state idx]
  (values iter-filter-impl [predicate iter state] idx)) 


;; Map

(defn- iter-map-impl-1 [state idx ...]
  (when (nn idx)
    (values idx (call-1 ...))))


(defn- iter-map-impl [state idx]
  (iter-map-impl-1 state (iter-2 idx)))


(defn map [mapper iter state idx]
  (values iter-map-impl [mapper iter state] idx))


;; Extract

(defn- iter-extract-impl-1 [state idx key]
  (when (nn idx)
    (values idx (. state key))))


(defn- iter-extract-impl [state idx]
  (iter-extract-impl-1 state (iter-2 idx)))


(defn extract [container iter state idx]
  (values iter-extract-impl [container iter state] idx))


;; Zip

(defn- iter-zip-collect [s i nidx pidx state ...]
  (if (< 0 s)
    (let [(idx value) ((. state s) (. state (+ s 1)) (. pidx i))]
      (when (nn idx)
        (tset nidx i idx)
        (iter-zip-collect (- s 2) (- i 1) nidx pidx state value ...)))
    (values nidx ...)))


(defn- iter-zip-impl [state idx]
  (let [i state.n
        s (- (* i 2) 1)]
    (iter-zip-collect s i [] idx state)))
                                        
                         
(defn- zip-collect [n dest-state dest-idx iterator ...]
  (if iterator
    (do
      (table.insert dest-state (v1 iterator))
      (table.insert dest-state (v2 iterator))
      (table.insert dest-idx (v3 iterator))
      (zip-collect (+ n 1) dest-state dest-idx ...))
    (do
      (set dest-state.n n)
      (values iter-zip-impl dest-state (when (length dest-idx) dest-idx)))))


(defn zip [...]
  (zip-collect 0 [] [] ...))


(each [i a b c (zip (wrap (ipairs [1 2 3]))
                    (wrap (ipairs [5 6 7]))
                    (wrap (ipairs [-1 -2 -3])))]
  (print "R" i a b c))
