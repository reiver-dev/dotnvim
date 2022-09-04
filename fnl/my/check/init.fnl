(local reg (require "my.check.registry"))
(local evt (require "my.check.events"))
(local b (require "my.bufreg"))
(local u (require "my.util"))

(local new-id (u.counter))
(local client-ids {})


(fn buffer [bufnr]
  (let [t (type bufnr)]
    (assert (or (= t :nil)
                (= t :number) (.. "BUFNR must be number, got " t))))
  (if (and bufnr (< 0 bufnr))
    bufnr
    (vim.api.nvim_get_current_buf)))


(fn publish [id bufnr entries]
  (vim.schedule
    (fn []
      (vim.diagnostic.set id bufnr entries))))


(fn execute-checkers [bufnr event]
  (LOG "Execute checkers"
       :bufnr bufnr
       :event event
       :checkers (b.get-local bufnr :enabled-checkers))
  (let [enabled-checkers (b.get-local bufnr :enabled-checkers)]
    (when enabled-checkers
      (each [name client-id (pairs enabled-checkers)]
        (LOG "Launching checker" :bufnr bufnr :name name)
        (vim.schedule
          #(reg.run name bufnr
                    (fn [entries]
                      (publish client-id bufnr entries))))))))


(fn register [name run cancel]
  (when (not (. client-ids name))
    (tset client-ids name (vim.api.nvim_create_namespace name)))
  (reg.register name run cancel))


(fn enable [bufnr name]
  (var bufnr (buffer bufnr))
  (b.set-local bufnr :enabled-checkers name (. client-ids name))
  (evt.enable bufnr execute-checkers))


(fn disable [bufnr]
  (var bufnr (buffer bufnr))
  (b.set-local bufnr :enabled-checkers {})
  (evt.disable bufnr))


{: publish 
 : register 
 : enable 
 : disable} 
