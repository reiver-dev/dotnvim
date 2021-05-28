(module my.pack.telescope-fzy-native)


(defn setup []
  (_T :telescope :load_extension "fzy_native"))
