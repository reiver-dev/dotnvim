(module my.vararg)


(def table-new (require "table.new"))


(defn lj-pack [...]
  (let [count (select :# ...)
        tbl (table-new (+ count 1) 1)]
    (set tbl.n count)
    (for [i 1 count 1]
      (tset tbl i (select i ...)))
    tbl))


(defn lua-pack [...]
  (let [count (select :# ...)]
    (if (< 0 count)
      (let [args [...]]
        (set args.n count)
        args)
      {:n 0})))


(def pack (if table-new lj-pack lua-pack))


(defn- unpack-1 [n tbl ...]
  (if (< 0 n)
    (unpack-1 (- n 1) tbl (. tbl n) ...)
    ...))


(defn unpack [tbl]
  (when tbl
    (let [n (or tbl.n (length tbl))]
      (unpack-1 n tbl))))


(defn unpack-tail [tbl tail]
  (if (and tbl (< 0 tbl.n))
    (unpack-1 tbl.n tbl tail)
    tail))
