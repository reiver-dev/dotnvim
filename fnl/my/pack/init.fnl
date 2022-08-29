(fn setup []
  (each [_ name (ipairs [:netrw])]
    (let [modname (.. "my.pack." name)
          mod (require modname)
          setup-fn (. mod "setup")]
      (when setup-fn
        (setup-fn)))))


{: setup}
