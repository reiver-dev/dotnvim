(local str-byte string.byte)
(local str-sub string.sub)

(local fslash 47) ;; "/"
(local bslash 92) ;; "\\"

(local separator (if (= (vim.fn.has "win32") 1) "\\" "/"))


(fn winsep? [str pos]
  "Check if position STR[POS] is windows separator, either '\\' or '/' ."
  (let [c (str-byte str pos)]
    (or (= fslash c)
        (= bslash c))))


(fn posixsep? [str pos]
  "Check if position STR[POS] is posix separator."
  (= fslash (str-byte str pos)))


(local separator?
  (if (= separator "/")
    posixsep?
    winsep?))


(fn ltrim [str predicate]
  (let [len (length str)]
    (var i 1)
    (while (and (<= i len) (predicate str i))
      (set i (+ i 1)))
    (str-sub str i)))


(fn rtrim [str predicate]
  (var i (length str))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (str-sub str 1 i))


(fn trim [str predicate]
  (var begin 1)
  (var end (length str))
  (while (and (<= begin end) (predicate str begin))
    (set begin (+ begin 1)))
  (while (and (< begin end) (predicate str end))
    (set end (- end 1)))
  (str-sub str begin end))


(fn rkeepone [str predicate]
  (var i (length str))
  (while (and (> i 0) (predicate str i))
    (set i (- i 1)))
  (str-sub str 1 (+ i 1)))


(fn rcut [str predicate]
  (var i (length str))
  (while (and (< 0 i) (predicate str i))
    (set i (- i 1)))
  (while (and (< 0 i) (not (predicate str i)))
    (set i (- i 1)))
  (str-sub str 1 i))


(fn parent [str]
  (rcut str separator?))


(fn firstsep? [str]
  (separator? str 1))


(fn lastsep? [str]
  (separator? str (length str)))


(fn join [head tail]
  (if (or (separator? head (length head))
          (separator? tail 1))
    (.. head tail)
    (.. head separator tail)))


{: separator?
 : join
 : parent
 : rcut
 : rkeepone
 : trim
 : rtrim
 : ltrim}
