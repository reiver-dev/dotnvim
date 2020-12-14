(module my.buflog
  {require {l my.log
            r my.bufreg}})



(defn log [event]
  (let [expand vim.fn.expand]
    (l.log (.. "======= " event " ======="))
    (l.log "Data"
         :file  (expand "<afile>")
         :buffer (expand "<abuf>")
         :buftype (vim.api.nvim_buf_get_option (tonumber (expand "<abuf>")) :buftype)
         :loaded (vim.api.nvim_buf_is_loaded (tonumber (expand "<abuf>")))
         :curbuffer (vim.fn.bufnr "%")
         :curbufnr (vim.api.nvim_get_current_buf)
         :curfile (vim.fn.expand "%:p")
         :match (vim.fn.expand "<amatch>")
         :event vim.v.event
         :curbuftype vim.o.buftype
         :au event
         :dd (vim.fn.getbufvar (tonumber (expand "<abuf>")) "default_directory" "NIL")
         :reg (r.get-local (tonumber (expand "<abuf>"))))
    (l.log "------- END -------")))


(defn declare-event [event]
  (string.format
    "autocmd %s * call v:lua._T('my.buflog', 'log', '%s')"
    event event))


(defn declare-user-event [event]
  (string.format
    "autocmd User %s call v:lua._T('my.buflog', 'log', '%s')"
    event event))


(def events [:BufAdd :BufNew :BufCreate :BufNewFile
             :BufReadPre :BufRead :BufReadPost
             :BufHidden :BufUnload :BufDelete :BufWipeout
             ;;; :BufEnter :BufLeave
             :TermOpen :TermClose
             :BufFilePre :BufFilePost
             :FileType :VimEnter])


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
