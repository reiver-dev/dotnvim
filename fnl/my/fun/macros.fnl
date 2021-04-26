;;; Macros for fun library

(fn v1 [value]
  `(. ,value 1))

(fn v2 [value]
  `(. ,value 2))

(fn v3 [value]
  `(. ,value 3))


(fn fill-call-forms-rest [forms n count param ...]
  (if (<= n count)
    (do
      (tset forms n param)
      (fill-call-forms-rest forms (+ n 1) count ...))
    forms))


(fn fill-call-forms-get [forms n count tbl param ...]
  (if (<= n count)
    (if (and (sym? param) (= param `$))
      (do 
        (fill-call-forms-rest forms n (- count 1) ...))
      (do
        (tset forms n `(. ,tbl ,param))
        (fill-call-forms-get forms (+ n 1) count tbl ...)))
    forms))


(fn call [tbl ...]
  (fill-call-forms-get (list) 1 (select :# ...) tbl ...))


(fn make-method [func nargs wrap?]
  (var call `(,func))
  (var args [(sym :self)])
  (for [i 1 nargs]
    (let [a (sym (.. "arg" i))]
      (table.insert args a)
      (table.insert call a)))
  (for [i 1 3]
    (table.insert call `(. self ,i)))
  (when wrap?
    (set call `(new ,call)))
  (let [name (sym (.. :method "-" (tostring func)))]
    `(fn ,name ,args ,call)))


(fn make-export [func nargs wrap?]
 (var call `(,func))
 (var args [])
 (for [i 1 nargs]
   (let [a (sym (.. "arg" i))]
     (table.insert args a)
     (table.insert call a)))
 (let [tail `(make-iter)]
   (each [_ s (ipairs [:it :?state :?idx])]
     (let [s (sym s)]
       (table.insert args s)
       (table.insert tail s)))
   (table.insert call tail))
 (when wrap?
   (set call `(new ,call)))
 (let [name (sym (.. :export "-" (tostring func)))]
   `(fn ,name ,args ,call)))


(fn with-name [param]
  (values (tostring param) param))


(fn export [func nargs wrap?]
  (let [exp (make-export func nargs wrap?)
        met (make-method func nargs wrap?)]
    `(do
       (set ,(sym (.. :raw "." (tostring func))) ,func)
       (set ,(sym (.. :exports "." (tostring func))) ,exp)
       (set ,(sym (.. :methods "." (tostring func))) ,met))))


{: v1 : v2 : v3
 : with-name
 : call
 : export}

;;; fun/macros.fnl ends here
