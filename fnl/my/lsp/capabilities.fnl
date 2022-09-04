(local capabilities-state {})
(local capabilities-update-hook {})


(fn update-table [old new]
  (when (not= old new)
    (each [k v (pairs new)]
      (tset old k v))))


(fn capabilities []
  (when (not (next capabilities-state))
    (each [k v (pairs (vim.lsp.protocol.make_client_capabilities))]
      (tset capabilities-state k v)))
  capabilities-state)


(fn update [new-capabilities]
  (update-table (capabilities) new-capabilities)
  (each [_ hook (pairs capabilities-update-hook)]
    (hook capabilities-state)))


(fn update-with [func]
  (let [caps (capabilities)]
    (update caps (func caps))))


(fn hook [name func]
  (tset capabilities-update-hook name func))


(fn get []
  (capabilities))


{: update 
 : update-with 
 : hook 
 : get} 
