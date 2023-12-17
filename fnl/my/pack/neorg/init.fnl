;;; Neorg


(fn load-config []
  {:core.defaults {}
   :core.keybinds {:config
                   {:default_keybinds true
                    :neorg_leader "<Leader>o"}}})


(fn invoke-with-safe-env [f ...]
  ((setfenv f _G.neorg_sandbox) ...))


(fn isolate-neorg-env [package-path]
  (local neorg-env
    (or _G.neorg_sandbox
        (setmetatable
          {: table
           : string
           : math
           : io
           : os
           : coroutine
           : debug
           : vim
           : tonumber
           : tostring
           : type
           : pcall
           : xpcall
           : pairs
           : ipairs
           : rawget
           : rawset
           : rawequal
           : unpack
           : next
           : error
           : assert
           : require}
          {:__index _G
           :__newindex (fn [t k v]
                         (if (string.match k "_?neorg.*")
                           (tset _G k v)
                           (rawset t k v)))})))
  (set _G.neorg_sandbox neorg-env)
  (let [mods (_G.SCAN_MODULES (.. package-path "/lua"))]
    (fn neorg-loader [name]
      (-?> (. mods name)
           (loadfile)
           (invoke-with-safe-env name)))
    (each [name path (pairs mods)]
      (tset package.preload name neorg-loader))))


(fn setup [_ {: path}]
  (isolate-neorg-env path)
  (local neorg (require "neorg"))
  (neorg.setup {:load (load-config)
                :lazy_loading true})
  (_T :my.pack.neorg.autoload :setup))


{: setup}
