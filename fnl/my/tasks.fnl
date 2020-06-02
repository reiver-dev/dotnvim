(module my.tasks
  {require {pkg bootstrap.pkgmanager}})

(def- make-command
  "command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>")

(defn setup []
  (pkg.def 
    {:name :asyncrun
     :url "skywind3000/asyncrun.vim"
     :init (fn [] (vim.cmd make-command))})
  (pkg.def 
    {:name :asynctasks
     :url "skywind3000/asynctasks.vim"}))
