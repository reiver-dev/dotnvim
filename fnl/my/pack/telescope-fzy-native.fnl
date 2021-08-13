(module my.pack.telescope-fzy-native)


(defn- load-fzy []
  (let [modfile (. (vim.api.nvim_get_runtime_file "deps/fzy-lua-native/lua/native.lua" false) 1)]
    ((loadfile modfile))))

(defn setup []
  (set package.preload.fzy load-fzy)
  (_T :telescope :load_extension "fzy_native"))
