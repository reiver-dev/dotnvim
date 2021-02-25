(module my.ui.mode)

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
   :v :visual
   :V :visual
   visual-block :visual
   :i :insert
   :c :command
   :r :prompt
   :R :replace
   :s :select
   :S :select
   select-block :select
   :! :shell
   :t :terminal})


(def- mode-symbol
  {:normal :N
   :visual :V
   :insert :I
   :command :C
   :prompt :P
   :relace :R
   :select :S
   :shell :$
   :terminal :T})


(defn resolve-current []
  (. mode-symbol (. modemap (vim.fn.mode))))
