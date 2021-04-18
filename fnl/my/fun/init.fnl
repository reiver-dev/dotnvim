;;; Functional primitives

(local vararg (require "my.vararg"))

(local varpack vararg.pack)
(local varunpack vararg.unpack)

(local methods {})
(local exports {})
(local raw {})
(tset exports :raw raw)

(local ceil math.ceil)
(local abs math.abs)
(local iter-ipairs (ipairs []))
(local iter-pairs (pairs {}))
(local string-sub string.sub)
(local string-byte string.byte)


(import-macros
  {: v1 : v2 : v3
   : call
   : export}
  :my.fun.macros)


(fn empty [state idx])


(fn always [state idx]
  idx)


(fn to-string [self]
  "<iterator>")


(fn self-iterate [self state idx]
  (call self 1 $ state idx))


(local iterator-mt
  {:__call self-iterate
   :__index methods
   :__tostring to-string})


(fn iter-rpairs [state idx]
  (local idx (- idx 1))
  (when (not= 0 idx)
    (values idx (. state idx))))


(fn iter-string [state idx]
  (local idx (+ idx 1))
  (when (not= idx (length state))
    (let [char (string-sub state idx idx)]
      (values idx char))))


(fn iter-rev-string [state idx]
  (local idx (- idx 1))
  (when (not= 0 idx)
    (let [char (string-sub state idx idx)]
      (values idx char))))


(fn string-iter-chars [s]
  (if (not= 0 (length s))
    (values iter-string s 0)
    (values empty nil nil)))


(fn string-iter-chars-reversed [s]
  (if (not= 0 (length s))
    (values iter-rev-string s (+ (length s) 1))
    (values empty nil nil)))


(fn rpairs [tbl]
  (values iter-rpairs tbl (+ (length tbl) 1)))


(fn iter [it ?state ?idx]
  (match (type it)
    "table" (if (= iterator-mt (getmetatable it)) (values (. it 1) (. it 2) (. it 3))
              (not= 0 (length it)) (values iter-ipairs it 0)
              (values iter-pairs iter nil))
    "function" (values it ?state ?idx)
    "string" (string-iter-chars it)))


(fn new [it ?state ?idx]
  (setmetatable [(iter it ?state ?idx)] iterator-mt))


(set exports.new new)
(set exports.iter iter)

(set exports.str string-iter-chars)
(set exports.rstr string-iter-chars-reversed)
(set exports.rpairs rpairs)


;; Unit

(fn iter-unit [state idx]
  (when idx
    (values false state)))


(fn unit [value]
  (values iter-unit true value))


(set exports.unit unit)


;; Repeat

(fn iter-repeat [state idx]
  (values idx state))


(fn repeat [value]
  (values iter-repeat value true))


(set exports.repeat repeat)


;; Repeat N


(fn iter-repeat-n [state idx]
  (when (not= 0 idx)
    (values (- idx 1) state)))


(fn repeat-n [n value]
  (if (< 0 n)
    (values iter-repeat-n value n)
    (values empty nil nil)))


(set exports.repeat-n repeat-n)


;; Take N

(fn iter-take-1 [num-remaining idx ...]
  (when (not= nil idx)
    (values [(- num-remaining 1) idx] ...)))


(fn iter-take [state idx]
  (when (not= 0 (v1 idx))
    (iter-take-1 (v1 idx) (call state 1 2 $ (v2 idx)))))


(fn take [n iter state idx]
  (if (< 0 n)
    (values iter-take [iter state] [n idx])
    (values empty nil nil)))


(export take 1)


;; Take one

(fn iter-take-one-1 [idx ...]
  (when (not= idx nil)
    (values [false idx] ...)))


(fn iter-take-one [state idx]
  (when (v1 idx)
    (iter-take-one-1 (call state 1 2 $ (v2 idx)))))


(fn take-1 [iter state idx]
  (values iter-take-one [iter state] [true idx]))


(export take-1 0)


;; Take while

(fn iter-take-while-1 [state idx ...]
  (when (and (not= nil idx) (call state 1 $ ...))
    (values idx ...)))


(fn iter-take-while-kv-1 [state idx ...]
  (when (and (not= nil idx) (call state 1 $ idx ...))
    (values idx ...)))


(fn iter-take-while [state idx]
  (iter-take-while-1 state (call state 2 3 $ idx)))


(fn iter-take-while-kv [state idx]
  (iter-take-while-kv-1 state (call state 2 3 $ idx)))


(fn take-while [predicate iter state idx]
  (values iter-take-while [predicate iter state] idx))


(fn take-while-kv [predicate iter state idx]
  (values iter-take-while-kv [predicate iter state] idx))


(export take-while 1)


;; Enumerate

(fn iter-enumerate-1 [nidx idx ...]
  (when (not= nil idx)
    (values [(+ nidx 1) idx] (+ nidx 1) ...)))


(fn iter-enumerate [state idx]
  (iter-enumerate-1 (v1 idx) (call state 1 2 $ (v2 idx))))


(fn enumerate [iter state idx]
  (values iter-enumerate [iter state] [0 idx]))


(export enumerate 0)


;; KV

(fn kv-iter-1 [idx ...]
  (when (not= nil idx)
    (values idx idx ...)))


(fn kv-iter [state idx]
  (kv-iter-1 (call state 1 2 $ idx)))


(fn kv [iter state idx]
  (values iter-kv [iter state] idx))


(export kv 0)


;; Filter

(fn iter-filter-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ ...)
      (values idx ...)
      (iter-filter-1 state (call state 2 3 $ idx)))))


(fn iter-filter-kv-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ idx ...)
      (values idx ...)
      (iter-filter-1 state (call state 2 3 $ idx)))))


(fn iter-filter [state idx]
  (iter-filter-1 state (call state 2 3 $ idx)))


(fn iter-filter-kv [state idx]
  (iter-filter-kv-1 state (call state 2 3 $ idx)))


(fn filter [predicate iter state idx]
  (values iter-filter [predicate iter state] idx))


(fn filter-kv [predicate iter state idx]
  (values iter-filter [predicate iter state] idx))


(export filter 1)
(export filter-kv 1)


;; Map

(fn iter-map-1 [state idx ...]
  (when (not= nil idx)
    (values idx (call state 1 $ ...))))


(fn iter-map-kv-1 [state idx ...]
  (when (not= nil idx)
    (values idx (call state 1 $ idx ...))))


(fn iter-map [state idx]
  (iter-map-1 state (call state 2 3 $ idx)))


(fn iter-map-kv [state idx]
  (iter-map-kv-1 state (call state 2 3 $ idx)))


(fn map [mapper iter state idx]
  (values iter-map [mapper iter state] idx))


(fn map-kv [mapper iter state idx]
  (values iter-map-kv [mapper iter state] idx))


(export map 1)
(export map-kv 1)


;; Reduce

(fn fold-1 [func acc iter state idx ...]
  (if (not= nil idx)
    (fold-1 func (func acc ...) iter state (iter state idx))
    acc))


(fn fold [func acc iter state idx]
  (fold-1 func acc iter state (iter state idx)))


(fn reduce-1 [func iter state idx ...]
  (when (not= nil idx)
    (fold-1 func ... iter state (iter state idx))))


(fn reduce [func iter state idx]
  (reduce-1 func iter state (iter state idx)))


(export fold 2)
(export reduce 1)


;; Each

(fn foreach-1 [func iter state idx ...]
  (when (not= nil idx)
    (func ...)
    (foreach-1 func iter state (iter state idx))))


(fn foreach-kv-1 [func iter state idx ...]
  (while (not= nil idx)
    (func idx ...)
    (foreach-kv-1 func iter state (iter state idx))))


(fn foreach [func iter state idx]
  (foreach-1 func iter state (iter state idx)))


(fn foreach-kv [func iter state idx]
  (foreach-kv-1 func iter state (iter state idx)))


(export foreach 1)
(export foreach-kv 1)


;; Items

(fn iter-items-1 [state idx ...]
  (values idx idx ...))


(fn iter-items [state idx]
  (when (not= nil idx)
    (iter-items-1 state (call state 1 2 $ idx))))


(fn items [iter state idx]
  (values iter-items [iter state] idx))


(export items 0)


;; Collect

(fn array-append [result i iter state idx val]
  (if (not= idx nil)
    (do
      (tset result i val)
      (array-append result (+ i 1) iter state (iter state idx)))
    result))


(fn map-append [result iter state idx key val]
  (if (not= idx nil)
    (do
      (tset result key val)
      (map-append result iter state (iter state idx)))
    result))


(fn map-append-kv [result iter state idx val]
  (if (not= idx nil)
    (do
      (tset result idx val)
      (map-append result iter state (iter state idx)))
    result))


(fn to-table [iter state idx]
  (array-append [] 1 iter state (iter state idx)))


(fn to-map [iter state idx]
  (map-append {} iter state (iter state idx)))


(fn to-map-kv [iter state idx]
  (map-append-kv {} iter state (iter state idx)))


(fn add-to-table [tbl iter state idx]
  (array-append (or tbl []) (+ (length tbl) 1) iter state (iter state idx)))


(fn add-to-table-at [tbl n iter state idx]
  (array-append (or tbl []) (or n (+ (length tbl) 1)) iter state (iter state idx)))


(fn add-to-map [tbl iter state idx]
  (map-append (or tbl {}) iter state (iter state idx)))


(fn add-to-map-kv [tbl iter state idx]
  (map-append-kv (or tbl {}) iter state (iter state idx)))


(export to-table 0)
(export to-map 0)
(export to-map-kv 0)
(export add-to-table 1)
(export add-to-table-at 2)
(export add-to-map 1)
(export add-to-map-kv 1)


;; Extract

(fn iter-extract-1 [state idx key]
  (when (not= nil idx)
    (values idx (. state 1 key))))


(fn iter-extract [state idx]
  (iter-extract-1 state (call state 2 3 $ idx)))


(fn extract [container iter state idx]
  (values iter-extract [container iter state] idx))

(export extract 1)


;; Flatten

(fn iter-allpairs-impl-1 [state idx ...]
  (if (not= nil idx)
    (values idx ...)
    (let [oldstate (v2 state)]
      (when (= "table" (type oldstate.__index))
        (let [(newiter newstate newidx) (pairs oldstate.__index)]
          (tset state 1 newiter)
          (tset state 2 newstate)
          (iter-allpairs-impl-1 state (call state 2 3 $ newidx)))))))


(fn iter-allpairs-impl [state idx]
  (iter-allpairs-impl-1 state (call state 1 2 $ idx)))


(fn allpairs [iter state idx]
  (values iter-allpairs-impl [iter state] idx))


(export allpairs 0)


;; Dedup

(fn iter-dedup-impl-1 [state idx ...]
  (when (not= nil idx)
    (let [hashset (v1 state)
          val ...]
      (if (. hashset val)
        (iter-dedup-impl-1 state (call state 2 3 $ idx))
        (do
          (tset hashset val true)
          (values idx ...))))))


(fn iter-dedup-impl [state idx]
  (iter-allpairs-impl-1 state (call state 2 3 $ idx)))


(fn dedup [iter state idx]
  (values iter-dedup-impl [{} iter state] idx))


(export dedup 0)


;; Zip

(fn iter-zip-1 [i s nidx pidx state ...]
  (if (not= 0 i)
    (let [(idx value) ((. state s) (. state (+ s 1)) (. pidx i))]
      (when (not= nil idx)
        (tset nidx i idx)
        (iter-zip-1 (- i 1) (- s 2) nidx pidx state value ...)))
    (values nidx ...)))


(fn iter-zip [state idx]
  (iter-zip-1 (. state 1) (. state 2) [] idx state))


(fn zip-1 [iterfun count nidx nstate dest-state dest-idx iterator ...]
  (if (<= nidx count)
    (if (not= nil iterator)
      (do
        (tset dest-state nstate (v1 iterator))
        (tset dest-state (+ nstate 1) (v2 iterator))
        (tset dest-idx nidx (v3 iterator))
        (zip-1 iterfun count (+ nidx 1) (+ nstate 2) dest-state dest-idx ...))
      (error (string.format "Iterator is nil, pos: %d" nidx)))
    (do
      (tset dest-state 1 count)
      (tset dest-state 2 (+ 1 (* count 2)))
      (values iterfun dest-state (when (length dest-idx) dest-idx)))))


(fn zip [...]
  (zip-1 iter-zip (select :# ...) 1 3 [0 0] [] ...))


(set exports.zip zip)
(set methods.zip (fn [self ...] (zip self ...)))


;; Util

(local table-new (let [(ok mod) (pcall require "table.new")]
                    (if ok
                      mod
                      (fn [narr nmap]
                        []))))


(fn copyseq [seq ?into]
  (let [n (length seq)
        into (or ?into (table-new n 0))]
    (for [i 1 n]
      (tset into i (. seq i)))
    into))


(fn copymap [tbl ?into]
  (let [into (or ?into {})]
    (each [k v (pairs tbl)]
      (tset into k v))
    into))


exports

;;; fun/init.fnl ends here
