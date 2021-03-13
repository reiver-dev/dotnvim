(module my.ui)


(def- visual-block (string.char 22)) ;; ^V
(def- select-block (string.char 19)) ;; ^S

(def- normal [:n :no :nov :noV (.. :no visual-block)
              :niI :niR :niV])

(def- visual [:v :V visual-block])

(def- select [:s :S select-block])

(def- insert [:i :ic :ix])

(def- replace [:R :Rc :Rv :Rx])

(def- command [:c :cv :ce])

(def- prompt [:r :rm :r?])

(def- shell-pending [:!])

(def- terminal [:t])


(def- modemap
  {:n :normal
   :i :insert
   :v :visual
   :V :visual
   :\22 :visual ;; ^V
   :c :change
   :no :normal
   :s :special
   :S :special
   :\19 :special ;; ^S
   :ic :knowhow
   :R :replace})
