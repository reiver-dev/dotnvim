(local visual-block (string.char 22)) ;; ^V
(local select-block (string.char 19)) ;; ^S

(local normal [:n :no :nov :noV (.. :no visual-block)
               :niI :niR :niV])

(local visual [:v :V visual-block])

(local select [:s :S select-block])

(local insert [:i :ic :ix])

(local replace [:R :Rc :Rv :Rx])

(local command [:c :cv :ce])

(local prompt [:r :rm :r?])

(local shell-pending [:!])

(local terminal [:t])

(local modemap
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


(local mode-symbol
  {:normal :N
   :visual :V
   :insert :I
   :command :C
   :prompt :P
   :relace :R
   :select :S
   :shell :$
   :terminal :T})


(fn resolve-current []
  (. mode-symbol (. modemap (vim.fn.mode))))


{: resolve-current}
