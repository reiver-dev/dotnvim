(module my.pathsep)


(def separator 
  (let [s (vim.fn.fnamemodify (vim.fn.stdpath "config") ":p")]
    (s:sub -1))
  "Platform-dependent filesystem path separator")


(def fslash 47) ;; "/"
(def bslash 92) ;; "\\"


(defn winsep? [str i]
  (let [c (str:byte i)]
    (or (= fslash c)
        (= bslash c))))


(defn posixsep? [str i]
  (= fslash (str:byte i)))


(def separator?
  (if (= separator "/")
    posixsep?
    winsep?))


(defn ltrim [str predicate]
  (let [len (str:len)]
    (var i 1)
    (while (and (<= i len) (predicate str i))
      (set i (+ i 1)))
    (str:sub 1 i)))


(defn rtrim [str predicate]
  (var i (str:len))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (str:sub 1 i))


(defn rkeepone [str predicate]
  (var i (str:len))
  (while (and (> i 0) (predicate str i))
    (set i (- i 1)))
  (str:sub 1 (+ i 1)))


(defn rcut [str predicate]
  (var i (str:len))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (while (and (< 0 i) (not (predicate str i)))
    (set i (- i 1)))
  (str:sub 1 i))


(defn parent [str]
  (rcut str separator?))


(defn- firstsep? [str]
  (separator? str 1))


(defn- lastsep? [str]
  (separator? str (str:len)))


(defn join [head tail]
  (if (or (separator? head (head:len))
          (separator? tail 1))
    (.. head tail)
    (.. head separator tail)))
