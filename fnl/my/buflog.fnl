(module my.buflog
  {require {l my.log
            r my.bufreg}})



(defn log [event]
  (let [expand vim.fn.expand
        bufnr (vim.api.nvim_get_current_buf)]
    (l.log (.. "======= " event " ======="))
    (l.log "Data"
         :expand-file  (expand "<afile>")
         :expand-buffer (expand "<abuf>")
         :expand-match (vim.fn.expand "<amatch>")
         :fn-curbuf (vim.fn.bufnr "%")
         :fn-curfile (vim.fn.expand "%:p")
         :buf-number bufnr
         :buf-type vim.o.buftype
         :buf-loaded (vim.api.nvim_buf_is_loaded bufnr)
         :v-errmsg vim.v.errmsg
         :v-event vim.v.event
         :au event
         :dd (vim.fn.getbufvar (tonumber (expand "<abuf>")) "default_directory" "NIL")
         :reg (r.get-local (tonumber (expand "<abuf>"))))
    (l.log "------- END -------")
    nil))


(defn declare-event [event]
  (string.format
    "autocmd %s * ++nested call v:lua._T('my.buflog', 'log', '%s')"
    event event))


(defn declare-user-event [event]
  (string.format
    "autocmd User %s ++nested call v:lua._T('my.buflog', 'log', '%s')"
    event event))


(def events [:BufAdd :BufNew :BufNewFile
             :BufReadPre :BufRead :BufReadPost
             :BufHidden :BufUnload :BufDelete :BufWipeout
             :VimEnter
             ;;; :BufEnter :BufLeave
             :TermOpen :TermClose
             :BufFilePre :BufFilePost
             :FileType])


(def command
  (let [entries ["augroup buffer_log" "autocmd!"]]
    (each [i event (ipairs events)]
      (table.insert entries (declare-event event)))
    (each [i event (ipairs ["DefaultDirectory" "Projectile"])]
      (table.insert entries (declare-user-event event)))
    (table.insert entries "augroup END")
    (table.concat entries "\n")))
                 

(defn setup []
  (l.log "\n\n\nSETUP BUFLOG\n\n\n")
  (vim.api.nvim_exec command false))
