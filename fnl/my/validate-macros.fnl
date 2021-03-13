;;; Validation macros

(fn nil? [value] `(= ,value nil))
(fn number? [value] `(= (type ,value) "number"))
(fn coro? [value] `(= (type ,value) "thread"))

(fn validate [value ...]
  (assert (< 0 (select :# ...)) "No predicates provided")
  (let [varname (string.upper (tostring value))
        (expr msg) (if (= 1 (select :# ...))
                     (let [pred ...]
                       (values `(,pred ,value) (tostring pred)))
                     (let [predicates [...]
                           prednames []
                           expression `(or)]
                       (each [i p (ipairs predicates)]
                         (when p 
                           (table.insert expression `(,p ,value))
                           (table.insert prednames (tostring p))))
                       (values expression (table.concat prednames "|"))))
        errmsg (string.format "%s (%s) is not valid, got " varname msg)]
    `(assert ,expr (.. ,errmsg (type ,value)))))


{: nil?
 : number?
 : coro?
 : validate}

;;; validate-macros.fnl ends here
