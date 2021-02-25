(module my.checkers
  {require {chk my.check}})


(defn setup []
  (each [_ name (ipairs [:flake8 :mypy])]
    (let [mod (require (.. "my.checkers." name))]
      (chk.register name mod.run mod.cancel))))
