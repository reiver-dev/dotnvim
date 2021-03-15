(module my.checkers
  {require {chk my.check}})


(defn setup []
  (each [_ name (ipairs [:flake8 :mypy])]
    (let [mod (.. "my.checkers." name)]
      (chk.register name
                    (fn [...] (_T mod :run ...))
                    (fn [...] (_T mod :cancel ...))))))
