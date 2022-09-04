(fn upvalues-iter [state idx]
  (local idx (+ idx 1))
  (local (name value) (debug.getupvalue state idx))
  (when (not= name nil)
    (values idx name value)))


(fn upvalues [func]
  (values upvalues-iter func 0))


;; Monkey-patch telescope fzy to output line index instead of line string
(local fzy-filter-impl
  (let [native nil
        fzy nil]
    ;; Upvalues copied from original function
    (fn [needle lines case-sensitive?]
      (local case-sensitive (or case-sensitive? false))
      (local has-match native.has_match)
      (local get-positions fzy.positions)

      (var pos 0)
      (local result {})
      (for [i 1 (length lines)]
        (local line (. lines i))
        (when (= 1 (has-match needle line case-sensitive))
          (local (positions score) (get-positions needle line case-sensitive))
          (tset result pos [i positions score])
          (set pos (+ pos 1))))
      result)))


(fn copy-upvalues [f-to f-from]
  (local tovals (collect [i name value (upvalues f-to)]
                  (values name i)))
  (each [i name value (upvalues f-from)]
    (let [toidx (. tovals name)]
      (when (not= toidx nil)
        (debug.setupvalue f-to toidx value))))
  f-to)


(fn patch-fzy [mod]
  (collect [name func (pairs mod)]
    (values name (match name
                   "filter" (copy-upvalues fzy-filter-impl func)
                   _ func))))


(fn extract-mod [extension]
  (var mod nil)
  (each [i name value (upvalues extension.native_fzy_sorter)
         :until (not= mod nil)]
    (when (= name "native_lua_mod")
      (set mod value)))
  mod)


(fn setup []
  (let [extension (_T :telescope :load_extension "fzy_native")
        mod (extract-mod extension)]
    (set package.loaded.fzy (patch-fzy mod))))


{: setup} 
