(module my.pack)

(defn setup []
  (each [_ name (ipairs [:fzf :netrw])]
    (let [modname (.. "my.pack." name)
          mod (require modname)
          setup-fn (. mod "setup")]
      (when setup-fn
        (setup-fn)))))
