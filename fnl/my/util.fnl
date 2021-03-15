(module my.util)


(def clock vim.loop.hrtime)


(defn nothing []
  "Do nothing, return nothing."
  nil)


(defn identity [id]
  "Return first argument."
  id)


(defn str-join [sep ...]
  "Join VARARG of string with SEP."
  (table.concat [...] sep))


(def- inspect-1
  (match (pcall (fn [] (require "aniseed.deps.fennelview")))
    (true view) view
    _ vim.inspect))


(defn inspect [first ...]
  "Inspect each of VARARG elements."
  (if (= (select :# ...) 0)
    (inspect-1 first)
    (values (inspect-1 first) (inspect ...))))


(defn bench [name fun]
  (var i 1000)
  (while (< 0 i)
    (fun)
    (set i (- i 1)))
  (let [begin (clock)]
    (var i 100000)
    (while (< 0 i)
      (fun)
      (set i (- i 1)))
    (let [end (clock)]
      (log "Bench" :name name :time (- end begin)))))


(defn- cycle-iter [state param a b c]
  (let [param (+ 1 (% param state.end))]
    (when (not= param state.begin)
      (values param (. state.table param)))))


(defn cycle [begin tbl]
  (if (<= begin 0)
    (ipairs tbl)
    (let [end (length tbl)
          begin (% begin end)]
      (values cycle-iter {:begin begin :end end :table tbl} begin))))


(defn- cycle-apply-impl [func begin end idx]
  (when (and (not= begin idx) (func idx))
    (cycle-apply-impl func begin end (+ 1 (% idx end)))))


(defn cycle-apply [func idx end]
  (if (<= idx 0)
    (when (and (< 0 end) (func 1) (< 1 end))
      (cycle-apply-impl func 1 end 2))
    (let [idx (% idx end)
          begin (if (not= idx 0) idx end)]
      (cycle-apply-impl func begin end (+ 1 (% idx end))))))


(defn- nset-1 [map n key ...]
  (if (< 2 n)
    (do
      (var nested (. map key))
      (when (not nested)
        (let [new {}]
          (tset map key new)
          (set nested new)))
      (nset-1 nested (- n 1) ...))
    (do
      (tset map key ...)
      ...)))
  

(defn nset [map ...]
  "Set MAP value by key. VARARG is sequence of keys and last value.
  If multiple keys supplied, they are used to traverse or create nested maps."
  (nset-1 map (select :# ...) ...))


(defn- nget-1 [map n key ...]
  (let [nested (. map key)]
    (if (and (< 1 n) nested)
      (nget-1 nested (- n 1) ...)
      nested)))


(defn nget [map ...]
  "Get value from MAP by key. VARARG is sequence of keys.
  If multiple keys supplied, they are used to traverse nested maps."
  (nget-1 map (select :# ...) ...))


(defn- nupdate-1 [map n key ...]
  (if (< 2 n)
    (do
      (var nested (. map key))
      (when (not nested)
        (let [new {}]
          (tset map key new)
          (set nested new)))
      (nupdate-1 nested (- n 1) ...))
    (do
      (let [func ...
            result (func (. map key))]
        (tset map key result)
        result))))


(defn nupd [map ...]
  (nupdate-1 map (select :# ...) ...))


(defn counter []
  (var counter 0)
  (fn []
    (let [val (+ counter 1)]
      (set counter val)
      val)))


;;; util.fnl ends here
