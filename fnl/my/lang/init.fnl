(module my.lang)

(defn setup []
  (each [_ name (ipairs [:cpp :python])]
    (let [mod (require (.. "my.lang." name))
          setup-fn (. mod :setup)]
      (when setup-fn (setup-fn)))))
