(fn setup []
  (local chk (require "my.check"))
  (each [_ name (ipairs [:flake8 :mypy])]
    (let [mod (.. "my.checkers." name)]
      (chk.register name
                    (fn [...] (_T mod :run ...))
                    (fn [...] (_T mod :cancel ...))))))

{: setup}
