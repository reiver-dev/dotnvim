(fn fzf-run [name opts bang]
  ((. vim.fn "fzf#run") ((. vim.fn "fzf#wrap") name opts bang)))


(fn fzf-files [path bang]
  (vim.cmd (.. (if bang "Files! " "Files ") path)))


(fn files []
  (fzf-files (or vim.b.projectile "")))


(fn hg-check-root []
  (vim.fn.system "hg root 2>/dev/null ||:"))


(fn hg-root []
  (string.gsub (hg-check-root) "\n" ""))


(fn hg-files [opts]
  (when (or (not opts.path) (= "" opts.path))
    (set opts.path (vim.fn.getcwd)))
  (fzf-run "hgfiles"
           {:source "hg files ."
            :sink "e"
            :dir opts.path
            :options "-m --prompt \"HgFiles> \""}
           0))


(fn projectile-hg-files []
  (fzf-run "hgfiles"
           {:source (.. "hg files " (vim.fn.fnameescape vim.b.projectile))
            :dir (hg-root)
            :sink "e"
            :options "-m --prompt \"HgFiles> \""}
           0))


(local commands
  "command! -bang ProjectileFiles lua _T('my.pack.fzf', 'files', '<bang>0')
  command! -bang ProjectileHgFiles lua _T('my.pack.fzf', 'projectile-hg-files', '<bang>0')
  command! -nargs=? -complete=dir HgFiles lua _T('my.pack.fzf', 'hg-files', { path = <q-args> })
  ")


(fn setup []
  (vim.api.nvim_exec commands false))


{: files 
 : hg-files 
 : projectile-hg-files 
 : setup} 
