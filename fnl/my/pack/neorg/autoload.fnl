(var HOOK {})


(fn invoke-pending [neorg hooks]
  (each [name hook (pairs hooks)]
    (match (xpcall (fn [] (hook neorg)) debug.traceback)
      (false err)
      (vim.notify (string.format "Neorg hook error: %s\nMessage: %s\n"
                                 name err)
                  vim.log.levels.ERROR))))


(fn run [name func]
  (local neorg package.loaded.neorg)
  (if neorg
    (if (neorg.is_loaded)
      (invoke-pending neorg {name func})
      (neorg.callbacks.on_event
        :core.started #(invoke-pending package.loaded.neorg {name func})))
    (tset HOOK name func)))


(fn setup []
  (local neorg (require "neorg"))
  (local hooks HOOK)
  (set HOOK {})
  (if (neorg.is_loaded)
    (invoke-pending neorg hooks)
    (neorg.callbacks.on_event
      :core.started #(invoke-pending package.loaded.neorg hooks))))


{: run : setup}
