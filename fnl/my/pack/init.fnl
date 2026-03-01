(fn setup []
  (each [_ name (ipairs [])]
    (let [modname (.. "my.pack." name)
          mod (require modname)
          setup-fn (. mod "setup")]
      (when setup-fn
        (setup-fn)))))


(fn start-job [name command cwd]
  (let [bufnr (vim.api.nvim_create_buf true true)
        opts {:cwd cwd
              :on_exit (fn [jobid data event]
                         (vim.notify (string.format "%s exited: %d" name data)))
              :term true}]
    (vim.cmd (string.format ":vertical botright sbuffer %d" bufnr))
    (vim.fn.jobstart command opts)))


(fn keep-window-finalize [oldwin ok ...]
  (vim.api.nvim_set_current_win oldwin)
  (when (not ok) (error ...))
  ...)


(fn keep-window [func ...]
  (let [curwin (vim.api.nvim_get_current_win)
        argc (select :# ...)
        argv [...]]
    (keep-window-finalize
      curwin (xpcall #(func (unpack argv 1 argc)) debug.traceback))))


(fn start [name command cwd]
  (keep-window start-job name command cwd))


(fn installed? [name]
  (local ok (pcall vim.pack.get [name] {:info false}))
  ok)


{: setup
 : start
 : installed?}
