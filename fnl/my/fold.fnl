(module my.fold)


(defn try-fold-impl [fun acc iter state idx ...]
  (if (~= idx nil)
    (do
      (let [(ok acc) (fun acc ...)]
        (if ok
          (try-fold-impl fun acc iter state (iter state idx))
          acc)))
    acc))


(defn try-fold [fun acc iter state idx]
  (try-fold-impl fun acc iter state (iter state idx)))


(defn always [fold]
  (fn [acc ...]
    (values true (fold acc ...))))


(defn fold-impl [fun acc iter state idx ...]
  (if (~= idx nil)
    (fold-impl fun (fun acc ...) iter state (iter state idx))
    acc))


(defn fold [fun acc iter state idx]
  (fold-impl fun acc iter state (iter state idx)))


(defn take [n fold]
  (var i n)
  (fn [acc ...]
    (set i (- i 1))
    (if (> i 0)
      (fold acc ...)
      (values false acc))))
      

(defn take-while [predicate fold]
  (fn [acc ...]
    (if (predicate ...)
      (fold acc ...)
      (values false acc))))


(defn enumerate [fold]
  (var i 0)
  (fn [acc ...]
    (set i (+ i 1))
    (fold acc i ...)))


(defn filter [predicate fold]
  (fn [acc ...]
    (if (predicate ...)
      (fold acc ...)
      (values true acc))))


(defn map [mapper fold]
  (fn [acc ...]
    (fold acc (mapper ...))))


(defn- array-append [result i iter state idx val]
  (if (~= idx nil)
    (do
      (tset result i val)
      (array-append result (+ i 1) iter state (iter state idx)))
    result))


(defn- map-append [result iter state idx val]
  (if (~= idx nil)
    (do 
      (tset result idx val)
      (map-append result iter state (iter state idx)))
    result))


(defn totable [iter state idx]
  (array-append [] 0 iter state idx))


(defn tomap [iter state idx]
  (map-append {} iter state idx))


(defn store [acc key item]
  (tset acc key item)
  acc)


;;; fold.fnl ends here
