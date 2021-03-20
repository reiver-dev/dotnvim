(module my.pack.asyncrun)

(def- make-command
  "command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>")

(defn setup []
  (vim.cmd make-command))
  
