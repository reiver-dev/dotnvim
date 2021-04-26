(module my.pathsep)

(def- str-byte string.byte)
(def- str-sub string.sub)

(def- fslash 47) ;; "/"
(def- bslash 92) ;; "\\"


(def separator
  (let [s (vim.fn.fnamemodify (vim.fn.stdpath "config") ":p")]
    (str-sub s -1))
  "Platform-dependent filesystem path separator")


(defn winsep? [str pos]
  "Check if position STR[POS] is windows separator, either '\\' or '/' ."
  (let [c (str-byte str pos)]
    (or (= fslash c)
        (= bslash c))))


(defn posixsep? [str pos]
  "Check if position STR[POS] is posix separator."
  (= fslash (str-byte str pos)))


(def separator?
  (if (= separator "/")
    posixsep?
    winsep?))


(defn ltrim [str predicate]
  (let [len (length str)]
    (var i 1)
    (while (and (<= i len) (predicate str i))
      (set i (+ i 1)))
    (str-sub str i)))


(defn rtrim [str predicate]
  (var i (length str))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (str-sub str 1 i))


(defn trim [str predicate]
  (var begin 1)
  (var end (length str))
  (while (and (<= begin end) (predicate str begin))
    (set begin (+ begin 1)))
  (while (and (< begin end) (predicate str end))
    (set end (- end 1)))
  (str-sub str begin end))


(defn rkeepone [str predicate]
  (var i (length str))
  (while (and (> i 0) (predicate str i))
    (set i (- i 1)))
  (str-sub str 1 (+ i 1)))


(defn rcut [str predicate]
  (var i (length str))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (while (and (< 0 i) (not (predicate str i)))
    (set i (- i 1)))
  (str-sub str 1 i))


(defn parent [str]
  (rcut str separator?))


(defn- firstsep? [str]
  (separator? str 1))


(defn- lastsep? [str]
  (separator? str (length str)))


(defn join [head tail]
  (if (or (separator? head (length head))
          (separator? tail 1))
    (.. head tail)
    (.. head separator tail)))
