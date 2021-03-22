(module my.check.events)


(defonce- buffer-state {})


(def- events [:BufEnter
              :WinEnter
              :BufWritePost
              :CursorHold
              :CursorHoldI
              :InsertLeave
              :FocusGained
              :CmdlineLeave
              :ShellCmdPost])


(def- autocmd-trigger-event
    "autocmd %s <buffer=%d> lua _T('my.check.events', 'trigger', '%s')")


(def- autocmd-template
  (string.format
    "augroup check
    autocmd! %s <buffer=%%d> lua _T('my.check.events', 'trigger')
    augroup END"
    (table.concat events ",")))


(def- autocmd-disable
  "augroup check
  autocmd! * <buffer=%d>
  augroup END")


(defn- initialize-events [bufnr]
  (vim.cmd "augroup check")
  (vim.cmd (string.format "autocmd! * <buffer=%d>" bufnr))
  (each [i event (ipairs events)]
    (vim.cmd (autocmd-trigger-event:format event bufnr event)))
  (vim.cmd "augroup END"))


(defn- disable-events [bufnr]
  (vim.api.nvim_exec (autocmd-disable:format bufnr) false))


(defn- run-change-hook [bufnr]
  (let [state (. buffer-state bufnr)]
    (tset state :has-edits false)
    ((. state :callback) bufnr)))


(defn- on-reload [_event bufnr]
  (let [state (. buffer-state bufnr)]
    (when (. state :enabled)
      (run-change-hook bufnr)))
  false)


(defn- on-detach [_event bufnr]
  (tset buffer-state bufnr nil)
  (when (vim.api.nvim_buf_is_valid bufnr)
    (disable-events bufnr))
  false)


(defn- on-bytes [event bufnr tick start-row start-col offset
                 old-end-row old-end-col old-length
                 new-end-row new-end-col new-length]
  (let [state (. buffer-state bufnr)]
    (set state.has-edits true)
    (not state.enabled)))


(defn- on-changedtick [event bufnr tick]
  (let [state (. buffer-state bufnr)]
    (set state.has-edits true)
    (not state.enabled)))


(defn enable [bufnr callback]
  (let [state (. buffer-state bufnr)]
    (if state
      (do
        (tset state :callback callback))
      (do
        (vim.api.nvim_buf_attach bufnr false
                                 {:on_bytes on-bytes
                                  :on_changedtick on-changedtick
                                  :on_reload on-reload
                                  :on_detach on-detach})
        (tset buffer-state bufnr {:callback callback
                                  :has-edits true
                                  :enabled true})
        (initialize-events bufnr)))))
  

(defn disable [bufnr]
  (tset (. buffer-state) :enabled false)
  (disable-events bufnr))


(defn trigger [event]
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
        state (. buffer-state bufnr)]
    (when (and state state.has-edits)
      (run-change-hook bufnr))))
