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


(defn publish [id bufnr entries]
  (vim.schedule
    (fn []
      (vim.diagnostic.set id bufnr entries))))


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
    (tset client-ids name (vim.api.nvim_create_namespace name)))
  (reg.register name run cancel))


(defn enable [bufnr name]
  (var bufnr (buffer bufnr))
  (b.set-local bufnr :enabled-checkers name (. client-ids name))
  (evt.enable bufnr execute-checkers))
