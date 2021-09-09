(module my.lsp.capabilities)


(defonce- capabilities-state {})


(defn- update-table [old new]
  (when (not= old new)
    (each [k v (pairs new)]
      (tset old k v))))


(defn- capabilities []
  (when (not (next capabilities-state))
    (each [k v (pairs (vim.lsp.protocol.make_client_capabilities))]
      (tset capabilities-state k v)))
  capabilities-state)


(defn update [new-capabilities]
  (update-table (capabilities) new-capabilities))


(defn update-with [func]
  (let [caps (capabilities)]
    (update caps (func caps))))


(defn get []
  (capabilities))