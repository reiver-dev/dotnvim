(module my.check
  {require {reg my.check.registry
            evt my.check.events
            b my.bufreg
            u my.util}})


(defonce- new-id (u.counter))
(defonce- client-ids {})
 

(defn- buffer [bufnr]
  (let [t (type bufnr)]
    (assert (or (= t :nil)
                (= t :number) (.. "BUFNR must be number, got " t))))
  (if (and bufnr (< 0 bufnr))
    bufnr
    (vim.api.nvim_get_current_buf)))


(defn publish [client_id bufnr entries]
  (let [method "textDocument/publishDiagnostics"
        err nil
        opts nil
        handler (. vim.lsp.handlers method)
        params {:uri (vim.uri_from_bufnr bufnr)
                :diagnostics entries}
        ctx {: method
             : client_id
             : bufnr}]
    (vim.schedule
      (fn []
        (let [(ok res) (xpcall handler debug.traceback
                               err params ctx opts)]
          (when (not ok)
            (error res)))))))


(defn- execute-checkers [bufnr]
  (log "Execute checkers"
       :bufnr bufnr
       :checkers (b.get-local bufnr :enabled-checkers))
  (let [enabled-checkers (b.get-local bufnr :enabled-checkers)]
    (when enabled-checkers
      (each [name client-id (pairs enabled-checkers)]
        (log "Launching checker" :bufnr bufnr :name name)
        (reg.run name bufnr
                 (fn [entries]
                   (publish client-id bufnr entries)))))))


(defn register [name run cancel]
  (when (not (. client-ids name))
    (tset client-ids name (- (+ 100 (new-id)))))
  (reg.register name run cancel))


(defn enable [bufnr name]
  (var bufnr (buffer bufnr))
  (b.set-local bufnr :enabled-checkers name (. client-ids name))
  (evt.enable bufnr execute-checkers))
