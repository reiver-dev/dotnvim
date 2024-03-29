;;; Functional primitives

(import-macros
  {: v1 : v2 : v3
   : call
   : export}
  :my.fun.macros)

(local methods {})
(local exports {})
(local raw {})

(tset exports :raw raw)
(tset exports :iter raw)

(local iter-ipairs (ipairs []))
(local iter-pairs (pairs {}))
(local string-sub string.sub)
(local string-byte string.byte)
(local string-find string.find)
(local bit-and bit.band)


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


(fn apply-next [func idx ...]
  (when (not= nil idx)
    (values idx (func ...))))


(fn apply-next-kv [func idx ...]
  (when (not= nil idx)
    (values idx (func idx ...))))


(fn pass-next [idx ...]
  (when (not= nil idx)
    ...))


(fn iter-rpairs [state idx]
  (local idx (- idx 1))
  (when (not= 0 idx)
    (values idx (. state idx))))


(fn iter-string [state idx]
  (when (not= idx (length state))
    (let [idx (+ idx 1)
          char (string-sub state idx idx)]
      (values idx char))))


(fn iter-rev-string [state idx]
  (when (not= 1 idx)
    (let [idx (- idx 1)
          char (string-sub state idx idx)]
      (values idx char))))


(fn iter-bytes [state idx]
  (when (not= idx (length state))
    (let [idx (+ idx 1)
          val (string-byte state idx)]
      (values idx val))))


(fn iter-rev-bytes [state idx]
  (when (not= 1 idx)
    (let [idx (- idx 1)
          val (string-byte state idx)]
      (values idx val))))


(fn string-iter-chars [s]
  (values iter-string s 0))


(fn string-iter-chars-reversed [s]
  (if (not= 0 (length s))
    (values iter-rev-string s (+ (length s) 1))
    (values empty nil nil)))


(fn string-iter-bytes [s]
  (values iter-bytes s 0))


(fn string-iter-bytes-reversed [s]
  (if (not= 0 (length s))
    (values iter-rev-bytes s (+ (length s) 1))
    (values empty nil nil)))


(fn new-rpairs [tbl]
  (values iter-rpairs tbl (+ (length tbl) 1)))


(fn new-ipairs [tbl]
  (values iter-ipairs tbl 0))


(fn new-pairs [tbl]
  (values iter-pairs tbl nil))


(fn make-iter [it ?state ?idx]
  (match (type it)
    "function" (values it ?state ?idx)
    "table" (if (= iterator-mt (getmetatable it)) (values (. it 1) (. it 2) (. it 3))
              (not= 0 (length it)) (values iter-ipairs it 0)
              (values iter-pairs it nil))
    "string" (string-iter-chars it)))


(fn wrap-iter [it ?state ?idx]
  (match (type it)
    "function" [it ?state ?idx]
    "table" (if (= iterator-mt (getmetatable it)) it
              (not= 0 (length it)) [iter-ipairs it 0]
              [iter-pairs it])
    "string" [(string-iter-chars it)]))


(fn new [it ?state ?idx]
  (setmetatable (wrap-iter it ?state ?idx) iterator-mt))


(set raw.str string-iter-chars)
(set raw.rstr string-iter-chars-reversed)

(set raw.str-bytes string-iter-bytes)
(set raw.rstr-bytes string-iter-bytes-reversed)

(set raw.rpairs new-rpairs)
(set raw.ipairs new-ipairs)
(set raw.pairs new-pairs)

(set raw.empty empty)

(set exports.str (fn [s] (new (string-iter-chars s))))
(set exports.rstr (fn [s] (new (string-iter-chars-reversed s))))
(set exports.str-bytes (fn [s] (new (string-iter-bytes s))))
(set exports.rstr-bytes (fn [s] (new (string-iter-bytes-reversed s))))
(set exports.rpairs (fn [tbl] (new (new-rpairs tbl))))
(set exports.ipairs (fn [tbl] (new (new-ipairs tbl))))
(set exports.pairs (fn [tbl] (new (new-pairs tbl))))

(set exports.new new)
(set exports.go make-iter)

(set exports.empty (fn [] (new empty nil nil)))

;; Unit

(fn iter-unit [state idx]
  (when idx
    (values false state)))


(fn unit [value]
  (values iter-unit value true))


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


(export take 1 true)


;; Take one

(fn iter-take-one-1 [idx ...]
  (when (not= idx nil)
    (values [false idx] ...)))


(fn iter-take-one [state idx]
  (when (v1 idx)
    (iter-take-one-1 (call state 1 2 $ (v2 idx)))))


(fn take-one [iter state idx]
  (values iter-take-one [iter state] [true idx]))


(export take-one 0 true)


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


(export take-while 1 true)
(export take-while-kv 1 true)


;; Enumerate

(fn iter-enumerate-1 [nidx idx ...]
  (when (not= nil idx)
    (values [(+ nidx 1) idx] (+ nidx 1) ...)))


(fn iter-enumerate [state idx]
  (iter-enumerate-1 (v1 idx) (call state 1 2 $ (v2 idx))))


(fn enumerate [iter state idx]
  (values iter-enumerate [iter state] [0 idx]))


(export enumerate 0 true)


;; KV

(fn iter-kv-1 [idx ...]
  (when (not= nil idx)
    (values idx idx ...)))


(fn iter-kv [state idx]
  (iter-kv-1 (call state 1 2 $ idx)))


(fn kv [iter state idx]
  (values iter-kv [iter state] idx))


(export kv 0 true)


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
      (iter-filter-kv-1 state (call state 2 3 $ idx)))))


(fn iter-filter1-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ (select 1 ...))
      (values idx ...)
      (iter-filter-1 state (call state 2 3 $ idx)))))


(fn iter-filter1-kv-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ idx (select 1 ...))
      (values idx ...)
      (iter-filter-kv-1 state (call state 2 3 $ idx)))))


(fn iter-filter [state idx]
  (iter-filter-1 state (call state 2 3 $ idx)))


(fn iter-filter-kv [state idx]
  (iter-filter-kv-1 state (call state 2 3 $ idx)))


(fn iter-filter1 [state idx]
  (var (idx val) (call state 2 3 $ idx))
  (while (and (not= nil idx) (not (call state 1 $ val)))
    (set (idx val) (call state 2 3 $ idx)))
  (values idx val))


(fn iter-filter1-kv [state idx ...]
  (var (idx val) (call state 2 3 $ idx))
  (while (and (not= nil idx) (not (call state 1 $ idx val)))
    (set (idx val) (call state 2 3 $ idx)))
  (values idx val))


(fn filter [predicate iter state idx]
  (values iter-filter [predicate iter state] idx))


(fn filter-kv [predicate iter state idx]
  (values iter-filter-kv [predicate iter state] idx))


(fn filter1 [predicate iter state idx]
  (values iter-filter1 [predicate iter state] idx))


(fn filter1-kv [predicate iter state idx]
  (values iter-filter1-kv [predicate iter state] idx))


(export filter 1 true)
(export filter-kv 1 true)
(export filter1 1 true)
(export filter1-kv 1 true)

;; Reject

(fn iter-reject-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ ...)
      (iter-reject-1 state (call state 2 3 $ idx))
      (values idx ...))))


(fn iter-reject-kv-1 [state idx ...]
  (when (not= nil idx)
    (if (call state 1 $ idx ...)
      (iter-reject-kv-1 state (call state 2 3 $ idx))
      (values idx ...))))


(fn iter-reject [state idx]
  (iter-reject-1 state (call state 2 3 $ idx)))


(fn iter-reject-kv [state idx]
  (iter-reject-kv-1 state (call state 2 3 $ idx)))


(fn iter-reject1 [state idx]
  (var (idx val) (call state 2 3 $ idx))
  (while (and (not= nil idx) (call state 1 $ val))
    (set (idx val) (call state 2 3 $ idx)))
  (values idx val))


(fn iter-reject1-kv [state idx]
  (var (idx val) (call state 2 3 $ idx))
  (while (and (not= nil idx) (call state 1 $ idx val))
    (set (idx val) (call state 2 3 $ idx)))
  (values idx val))


(fn reject [predicate iter state idx]
  (values iter-reject [predicate iter state] idx))


(fn reject-kv [predicate iter state idx]
  (values iter-reject-kv [predicate iter state] idx))


(fn reject1 [predicate iter state idx]
  (values iter-reject1 [predicate iter state] idx))


(fn reject1-kv [predicate iter state idx]
  (values iter-reject1-kv [predicate iter state] idx))


(export reject 1 true)
(export reject-kv 1 true)
(export reject1 1 true)
(export reject1-kv 1 true)

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


(export map 1 true)
(export map-kv 1 true)


;; Reduce


(fn fold-call [func acc idx ...]
  (when (not= nil idx)
    (values idx (func acc ...))))


(fn fold [func acc iter state idx]
  (var (idx acc) (fold-call func acc (iter state idx)))
  (while (not= nil idx)
    (set (idx acc) (fold-call func acc (iter state idx))))
  acc)


(fn reduce [func iter state idx]
  (var (idx acc) (iter state idx))
  (while (not= nil idx)
    (set (idx acc) (fold-call func acc (iter state idx))))
  acc)


(export fold 2 false)
(export reduce 1 false)


;; Find


(fn find-1 [predicate iter state idx ...]
  (when (not= nil idx)
    (if (predicate ...) (values ...)
      (find-1 predicate iter state (iter state idx)))))


(fn find-kv-1 [predicate iter state idx ...]
  (when (not= nil idx)
    (if (predicate idx ...) (values ...)
      (find-1 predicate iter state (iter state idx)))))


(fn find [predicate iter state idx]
  (find-1 predicate iter state (iter state idx)))


(fn find-kv [predicate iter state idx]
  (find-kv-1 predicate iter state (iter state idx)))


(export find 1 false)
(export find-kv 1 false)


;; Each

(fn foreach-kv-1 [func iter state idx ...])


(fn foreach [func iter state idx]
  (var idx (apply-next func (iter state idx)))
  (while (not= nil idx)
    (set idx (apply-next func (iter state idx)))))


(fn foreach-kv [func iter state idx]
  (var idx (apply-next-kv func (iter state idx)))
  (while (not= nil idx)
    (set idx (apply-next-kv func (iter state idx)))))


(export foreach 1 false)
(export foreach-kv 1 false)


;; Collect

(fn array-insert [result i iter state idx val]
  (if (not= idx nil)
    (do
      (tset result i val)
      (array-insert result (+ i 1) iter state (iter state idx)))
    result))


(fn array-append [result i iter state idx val]
  (if (not= idx nil)
    (do
      (tset result i val)
      (array-append result (if val (+ i 1) i)) iter state (iter state idx))
    result))


(fn map-insert-pairs [result iter state idx key val]
  (if (not= idx nil)
    (do
      (tset result key val)
      (map-insert-pairs result iter state (iter state idx)))
    result))


(fn map-insert-kv [result iter state idx val]
  (if (not= idx nil)
    (do
      (tset result idx val)
      (map-insert-kv result iter state (iter state idx)))
    result))


(fn to-table [iter state idx]
  (array-insert [] 1 iter state (iter state idx)))


(fn to-map [iter state idx]
  (map-insert-pairs {} iter state (iter state idx)))


(fn to-map-kv [iter state idx]
  (map-insert-kv {} iter state (iter state idx)))


(fn add-to-table [tbl iter state idx]
  (if (not= nil tbl)
    (array-insert tbl (+ (length tbl) 1) iter state (iter state idx))
    (array-insert [] 1 iter state (iter state idx))))


(fn add-to-table-at [tbl n iter state idx]
  (if (not= nil tbl)
    (array-insert tbl (or n (+ (length tbl) 1)) iter state (iter state idx))
    (array-insert [] (or n 1) iter state (iter state idx))))


(fn add-to-map [tbl iter state idx]
  (map-insert-pairs (or tbl {}) iter state (iter state idx)))


(fn add-to-map-kv [tbl iter state idx]
  (map-insert-kv (or tbl {}) iter state (iter state idx)))


(export to-table 0)
(export to-map 0)
(export to-map-kv 0)
(export add-to-table 1)
(export add-to-table-at 2)
(export add-to-map 1)
(export add-to-map-kv 1)

;; Conditions

(fn boolean-call [func idx ...]
  (when (not= nil idx)
    (values idx (func ...))))


(fn any [func iter state idx]
  (var (idx cond) (boolean-call func (iter state idx)))
  (while (and (not= nil idx) (not cond))
    (set (idx cond) (boolean-call func (iter state idx))))
  cond)


(fn all [func iter state idx]
  (var (idx cond) (boolean-call func (iter state idx)))
  (while (and (not= nil idx) cond)
    (set (idx cond) (boolean-call func (iter state idx))))
  cond)


(export any 1 false)
(export all 1 false)


;; Extract

(fn iter-extract-1 [state idx key]
  (when (not= nil idx)
    (values idx (. state 1 key))))


(fn iter-extract [state idx]
  (iter-extract-1 state (call state 2 3 $ idx)))


(fn extract [container iter state idx]
  (values iter-extract [container iter state] idx))

(export extract 1 true)


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


(export allpairs 0 true)


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


(export dedup 0 true)


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


(fn zip-1 [count nidx nstate dest-state dest-idx iterator ...]
  (if (<= nidx count)
    (if (not= nil iterator)
      (do
        (tset dest-state nstate (v1 iterator))
        (tset dest-state (+ nstate 1) (v2 iterator))
        (tset dest-idx nidx (v3 iterator))
        (zip-1 count (+ nidx 1) (+ nstate 2) dest-state dest-idx ...))
      (error (string.format "Iterator is nil, pos: %d" nidx)))
    (do
      (tset dest-state 1 count)
      (tset dest-state 2 (+ 1 (* count 2)))
      (values iter-zip dest-state (when (length dest-idx) dest-idx)))))


(fn zip [...]
  (zip-1 (select :# ...) 1 3 [0 0] [] ...))


(do
  (set raw.zip zip)

  (fn export-zip [...]
    (new (zip ...)))

  (set exports.zip export-zip)

  (fn method-zip [self ...]
     (new (zip self ...)))

  (set methods.zip method-zip))

;;; Chain

(var iter-chain-1 nil)
(var iter-chain-2 nil)

(set iter-chain-2
     (fn [state state-pos idx]
       (iter-chain-1 state
                     state-pos
                     ((. state (- (* state-pos 3) 2))
                      (. state (- (* state-pos 3) 1))
                      idx))))


(set iter-chain-1
     (fn [state state-pos nidx ...]
       (if (= nidx nil)
         (when (not= nil (. state (+ (* state-pos 3) 1)))
           (iter-chain-2
             state
             (+ state-pos 1)
             (. state (* (+ state-pos 1) 3))))
         (values [state-pos nidx] ...))))


(fn iter-chain [state idx]
  (iter-chain-1 state
                (. idx 1)
                ((. state (- (* (. idx 1) 3) 2))
                 (. state (- (* (. idx 1) 3) 1))
                 (. idx 2))))


(fn chain-1 [state num-iterators i iterator ...]
  (if (> i num-iterators)
    (values iter-chain state [1 (. state 3)])
    (do
      (tset state (- (* 3 i) 2) (. iterator 1))
      (tset state (- (* 3 i) 1) (. iterator 2))
      (tset state (- (* 3 i) 0) (. iterator 3))
      (chain-1 state num-iterators (+ i 1) ...))))


(fn chain [...]
  (local i (select :# ...))
  (if
    (= i 0) (values empty nil nil)
    (= i 1) (let [it ...] (values (. it 1) (. it 2) (. it 3)))
    (chain-1 [] i 1 ...)))


(set raw.chain chain)
(fn exports.chain [...] (new (chain ...)))
(fn methods.chain [...] (new (chain ...)))


;;; String

(fn iter-string-split-plain [state idx]
  (local len (length (. state 1)))
  (when (not= idx len)
    (local idx (+ idx 1))
    (var (start stop) (string-find (. state 1) (. state 2) idx true))
    (if (not= nil start)
      (values stop (string-sub (. state 1) idx (- start 1)))
      (values len (string-sub (. state 1) idx len)))))


(fn iter-string-split-pattern [state idx]
  (local len (length (. state 1)))
  (when (not= idx len)
    (local idx (+ idx 1))
    (var (start stop) (string-find (. state 1) (. state 2) idx false))
    (if (not= nil start)
      (values stop (string-sub (. state 1) idx (- start 1)))
      (values len (string-sub (. state 1) idx len)))))


(fn string-split [sep text]
  (if (or (= "" text) (= "" sep))
    (values empty nil nil)
    (values iter-string-split-plain [text sep] 0)))


(fn string-split-pattern [sep text]
  (if (or (= "" text) (= "" sep))
    (values empty nil nil)
    (values iter-string-split-pattern [text sep] 0)))


(set raw.str-split string-split)
(set raw.str-split-pattern string-split-pattern)

(set exports.str-split (fn [sep text] (new (string-split sep text))))
(set exports.str-split-pattern (fn [sep text] (new (string-split-pattern sep text))))


(fn utf8-forward-step [val]
  (if
    (= (bit-and val 0x80) 0x00) 0
    (= (bit-and val 0xe0) 0xc0) 1
    (= (bit-and val 0xf0) 0xe0) 2
    (= (bit-and val 0xf8) 0xf0) 3
    (= (bit-and val 0xfc) 0xf8) 4
    (= (bit-and val 0xfe) 0xfc) 5
    0))


(fn utf8-forward [str at]
  (values at (+ at (utf8-forward-step (string-byte str at)))))


(fn utf8-backward [str at]
  (if (= (bit-and (string-byte str at) 0x80) 0x00) (values at at)
    (do
      (var nidx (- at 1))
      (while (and (not= nidx 1)
                  (= (bit-and (string-byte str nidx) 0xc0) 0x80))
        (set nidx (- nidx 1)))
      (values nidx at))))


(fn iter-utf8-pos [state idx]
  (when (< idx (length state))
    (local (fr to) (utf8-forward state (+ idx 1)))
    (values to fr to)))


(fn iter-utf8-pos-reversed [state idx]
  (when (< 1 idx)
    (local (fr to) (utf8-backward state (- idx 1)))
    (values fr fr to)))


(fn iter-utf8 [state idx]
  (when (< idx (length state))
    (local (fr to) (utf8-forward state (+ idx 1)))
    (values to (string-sub state fr to))))


(fn iter-utf8-reversed [state idx]
  (when (< 1 idx)
    (local (fr to) (utf8-backward state (- idx 1)))
    (values fr (string-sub state fr to))))


(fn utf8-pos [text]
  (if (< 0 (length text))
    (values iter-utf8-pos text 0)
    (values empty "" 0)))


(fn rutf8-pos [text]
  (if (< 0 (length text))
    (values iter-utf8-pos-reversed text (+ (length text) 1))
    (values empty "" 0)))


(fn utf8 [text]
  (if (< 0 (length text))
    (values iter-utf8 text 0)
    (values empty "" 0)))


(fn rutf8 [text]
  (if (< 0 (length text))
    (values iter-utf8-reversed text (+ (length text) 1))
    (values empty "" 0)))


(set raw.utf8-pos utf8-pos)
(set raw.rutf8-pos rutf8-pos)

(set raw.utf8 utf8)
(set raw.rutf8 rutf8)

(set exports.utf8-pos (fn [text] (new (utf8-pos text))))
(set exports.rutf8-pos (fn [text] (new (rutf8-pos text))))

(set exports.utf8 (fn [text] (new (utf8 text))))
(set exports.rutf8 (fn [text] (new (rutf8 text))))

;;; Vararg

(fn vfoldl-1 [i fun acc val ...]
  (if (= i 0)
    (fun acc val)
    (vfoldl-1 (- i 1) fun (fun acc val) ...)))


(fn vfoldl [fun acc ...]
  (local i (select :# ...))
  (if (= i 0)
    acc
    (vfoldl-1 (- i 1) fun acc ...)))


(fn vfoldr-1 [i fun val ...]
  (if (= i 0)
    val
    (fun val (vfoldr-1 (- i 1) fun ...))))


(fn vfoldr [fun val ...]
  (vfoldr-1 (select :# ...) fun val ...))


(fn vforeach-1 [i fun val ...]
  (if (= i 0)
    (fun val)
    (do
      (fun val)
      (vforeach-1 (- i 1) fun ...))))


(fn vforeach [fun ...]
  (local i (select :# ...))
  (if (= i 0) nil
    (vforeach-1 (- i 0) fun ...)))


(fn vall-1 [i fun val ...]
  (if (= i 1)
    (fun val)
    (if (fun val) (vall-1 (- i 1) fun ...)
      false)))


(fn vany-1 [i fun val ...]
  (if (= i 1)
    (fun val)
    (if (fun val) true
      (vany-1 (- i 1) fun ...))))


(fn vall [fun ...]
  (local i (select :# ...))
  (if
    (= i 0) false
    (= i 1) (let [val ...] (fun val))
    (vall-1 i fun ...)))


(fn vany [fun ...]
  (local i (select :# ...))
  (if
    (= i 0) false
    (= i 1) (let [val ...] (fun val))
    (vany-1 i fun ...)))


(fn vefoldl-1 [i n fun acc val ...]
  (if (= i 0)
    (fun acc n val)
    (vefoldl-1 (- i 1) (+ n 1) fun (fun acc n val) ...)))


(fn vefoldl [fun acc ...]
  (local i (select :# ...))
  (if (= i 0)
    acc
    (vefoldl-1 (- i 1) 1 fun acc ...)))


(fn vpfoldl-1 [i fun acc val ...]
  (if (= i 0)
    (fun acc val)
    (let [(cont acc) (fun acc val)]
      (if cont (vpfoldl-1 (- i 1) acc ...)
        (values false acc)))))


(fn vpfoldl [fun acc ...]
  (local i (select :# ...))
  (if (= i 0)
    (values false acc)
    (vpfoldl-1 (- i 1) 1 fun ...)))


(fn vpefoldl-1 [i n fun acc val ...]
  (if (= i 0)
    (fun acc n val)
    (let [(cont acc) (fun acc n val)]
      (if cont (vpfoldl-1 (- i 1) (+ n 1) fun acc ...)
        (values false acc)))))


(fn vpefoldl [fun acc ...]
  (local i (select :# ...))
  (if (= i 0)
    (values false acc)
    (vpefoldl-1 (- i 1) 1 fun acc ...)))


(set raw.vfoldl vfoldl)
(set raw.vefoldl vefoldl)
(set raw.vpfoldl vpfoldl)
(set raw.vpefoldl vpefoldl)

(set raw.vfoldr vfoldr)
(set raw.vforeach vforeach)

(set raw.vany vany)
(set raw.vall vall)

(set exports.vfoldl vfoldl)
(set exports.vefoldl vefoldl)
(set exports.vpfoldl vpfoldl)
(set exports.vpefoldl vpefoldl)

(set exports.vfoldr vfoldr)
(set exports.vforeach vforeach)

(set exports.vany vany)
(set exports.vall vall)


exports

;;; fun/init.fnl ends here
