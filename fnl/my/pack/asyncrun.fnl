(local make-command
  "command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>")

(fn setup []
  (vim.cmd make-command))


{: setup}
  
