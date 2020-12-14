(module my.project
  {require {util bootstrap.util
            fw my.fswalk
            a my.async
            p my.promise
            b my.bufreg}})

(def- interesting-files [".projectile" ".lnvim.fnl"])
(def- interesting-directories [".git" ".hg"])


(defn- empty? [str]
  (or (= nil str) (= "" str)))


(defn- non-empty? [str]
  (and str (~= "" str)))


(defn- directory? [path]
  (if (non-empty? path)
    (let [(res msg code) (vim.loop.fs_stat path)]
      (and res (= (. res :type) "directory")))
    false))


(defn- current-buffer-dir []
  (vim.fn.expand "%:p:h" 1))


(defn- git-check-root-at [dir]
  (util.with_directory
    dir (fn []
          (vim.fn.system "git rev-parse --show-toplevel 2>/dev/null ||:"))))
  

(defn- hg-check-root-at [dir]
  (util.with_directory
    dir (fn []
          (vim.fn.system "hg root 2>/dev/null ||:"))))


(defn git-root [dir]
  (string.gsub (git-check-root-at dir) "\n" ""))


(defn hg-root [dir]
  (string.gsub (hg-check-root-at dir) "\n" ""))


(defn- find-file-location [root name]
  (let [res (vim.fn.findfile name (.. root ";"))]
    (when (non-empty? res)
      (vim.fn.fnamemodify res ":h"))))


(defn projectile-file-root [dir]
  (find-file-location dir ".projectile"))


(def- project-providers 
  [[:projectile-file projectile-file-root] 
   [:git git-root]
   [:hg hg-root]])


(def- autocmd
  "augroup projectile
  autocmd!
  autocmd VimEnter,BufNew,BufNewFile,BufReadPre * lua _T('my.project', 'on-file-open')
  autocmd BufEnter * lua _T('my.project', 'on-file-enter')
  autocmd BufWritePost * lua _T('my.project', 'on-file-write')
  augroup END
  ")


(defn- find-project-root-1 [dir next tbl idx]
  (let [(idx value) (next tbl idx)]
    (when value
      (let [[name func] value
            root (func dir)]
        (if (empty? root)
          (find-project-root-1 dir next tbl idx)
          (values root name))))))


(defn- find-project-root [dir]
  (find-project-root-1 dir (ipairs project-providers)))


(defn- getbufvar [bufnr name]
  (match (pcall
           (fn []
             (vim.api.nvim_buf_get_var (or bufnr 0) name)))
    (true res) res
    _ ""))
  

(defn- setbufvar [bufnr name val]
  (vim.api.nvim_buf_set_var (or bufnr 0) name val))


(defn project-root [bufnr]
  (let [pr (b.get-local bufnr :project :root)]
    (if pr
      pr
      (getbufvar bufnr :projectile))))
        

(defn- set-project-root [bufnr path]
  (b.set-local bufnr :project :root path)
  (setbufvar bufnr :projectile path)
  (setbufvar bufnr :asyncrun_root path))


(defn default-directory [bufnr]
  (let [dd (b.get-local bufnr :directory)]
    (if dd
      dd
      (getbufvar bufnr :default_directory))))

      
(defn- set-default-directory [bufnr path]
  (b.set-local bufnr :directory path)
  (setbufvar bufnr :default_directory path))


(defn- find-nearest-provider [...]
  (var provider nil)
  (var shortest-path nil)
  (var shortest-len 1e10)
  (var longest-path nil)
  (var longest-len 0)
  (each [_ providers (ipairs [...])]
    (each [name entries (pairs providers)]
      (let [loc (. entries 1)
            loclen (if loc (loc:len) 0)]
        (when (< longest-len loclen)
          (set longest-len loclen)
          (set longest-path loc)
          (set provider name))
        (when (<= loclen shortest-len)
          (set shortest-len loclen)
          (set shortest-path loc)))))
  (values provider longest-path shortest-path))


(defn- fire-user-event [bufnr event]
  (when (vim.fn.exists (string.format "#User#%s" event))
    (let [cmd (string.format "doautocmd <nomodeline> User %s" event)]
      (vim.api.nvim_buf_call bufnr (fn [] (vim.cmd cmd))))))
  


(defn- fire-project-updated [bufnr]
  (fire-user-event bufnr "Projectile"))


(defn- fire-default-directory-updated [bufnr]
  (fire-user-event bufnr "DefaultDirectory"))


(defn- do-project-search [bufnr path]
  (let [(files dirs) (fw.async-gather path interesting-files
                                      interesting-directories)
        data {: files : dirs}]
    (let [lnvim (. files ".lnvim.fnl")]
      (when lnvim
        (b.set-local bufnr :dir-local lnvim)
        (tset files ".lnvim.fnl" nil)))
    (b.set-local bufnr :project :triggers data)
    (let [(name path) (find-nearest-provider files dirs)]
      (b.set-local bufnr :project :root path)
      (b.set-local bufnr :project :provider name)
      (vim.schedule 
        (fn []
          (when (vim.api.nvim_buf_is_valid bufnr)
            (setbufvar bufnr :projectile path)
            (setbufvar bufnr :projectile_provider name)
            (setbufvar bufnr :projectile_locs data)
            (fire-project-updated bufnr)))))))



(defn- defer-project-search [bufnr path]
  (p.new do-project-search bufnr path))


(defn- apply-default-directory [bufnr]
  (let [dd (default-directory bufnr)]
    (vim.api.nvim_buf_call 
      bufnr
      (fn []
        (let [dir (or (current-buffer-dir) (vim.fn.getcwd))]
          (when (~= dir dd)
            (set-default-directory bufnr dir)
            (defer-project-search bufnr dir)
            (fire-default-directory-updated bufnr)))))))


(defn on-file-open []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (when (and (empty? (vim.api.nvim_buf_get_option bufnr :buftype))
               (vim.api.nvim_buf_is_loaded bufnr))
      (let [file (vim.fn.expand "<afile>:p")
            oldfile (b.get-local bufnr :file)]
        (when (or (= oldfile nil) (~= file oldfile))
          (b.set-local bufnr :file file)
          (apply-default-directory bufnr))))))


(defn on-file-write []
  (on-file-open))


(defn on-file-enter []
  (when (empty? vim.bo.buftype)
    (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
          dd (default-directory bufnr)]
      (when (directory? dd)
        (vim.cmd (.. "lcd " dd))))))


(defn setup []
  (set vim.b.projectile "")
  (vim.api.nvim_exec autocmd false))
  
;;; project.fnl ends here
