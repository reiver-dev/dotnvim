(fn setup []
  (each [_ name (ipairs [:python])]
    (let [mod (require (.. "my.lang." name))
          setup-fn (. mod :setup)]
      (when setup-fn (setup-fn)))))


{: setup}
