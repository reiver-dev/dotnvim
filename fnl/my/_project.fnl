(local fw (require "my.fswalk"))
(local a  (require "my.async"))
(local p (require "my.promise"))
(local b (require "my.bufreg"))


(local interesting-files [".projectile" ".lnvim.fnl"])
(local interesting-directories [".git" ".hg"])


(fn getbufvar [bufnr name]
  "Get buffer-local variable for BUFNR buffer by variable NAME."
  (match (pcall
           (fn []
             (vim.api.nvim_buf_get_var (or bufnr 0) name)))
    (true res) res
    _ ""))
  

(fn setbufvar [bufnr name value]
  "Assign buffer-local variable for BUFNR buffer by variable NAME to VALUE."
  (vim.api.nvim_buf_set_var (or bufnr 0) name value))


(fn project-root [bufnr]
  "Provide project root for BUFNR buffer."
  (let [pr (b.get-local bufnr :project :root)]
    (if pr
      pr
      (getbufvar bufnr :projectile))))
        

(fn find-nearest-provider [...]
  "Find project provider entry from multiple arrays
  which has with longest path."
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


(fn fire-user-event [bufnr event]
  "Execute autocmd user event for BUFNR buffer by EVENT name."
  (when (vim.fn.exists (string.format "#User#%s" event))
    (let [cmd (string.format "doautocmd <nomodeline> User %s" event)]
      (vim.api.nvim_buf_call bufnr (fn [] (vim.cmd cmd))))))
  

(fn fire-project-updated [bufnr]
  "Execute autocmd Projectile for BUFNR buffer."
  (fire-user-event bufnr "Projectile"))


(fn do-project-search [bufnr path]
  "Perform search for project-related files.
  BUFNR is buffer number. PATH is intended directory within project."
  (let [(files dirs) (fw.async-gather path interesting-files
                                      interesting-directories)
        data {: files : dirs}]
    (LOG "Defer search done" :bufnr bufnr)
    (LOG "Defer search done -- props" :loc (b.get-local bufnr))
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
            (setbufvar bufnr :asyncrun_root path)
            (setbufvar bufnr :projectile_provider name)
            (setbufvar bufnr :projectile_locs data)
            (fire-project-updated bufnr)))))))


(fn defer-project-search [bufnr path]
  "Schedule search for project-related files.
  BUFNR is buffer number. PATH is intended directory within project."
  (let [l (b.get-local bufnr)]
    (LOG "Defer search start" :loc l))
  (p.new do-project-search bufnr path))


(fn on-directory-changed [bufnr directory]
  (defer-project-search bufnr directory))


(fn setup []
  (let [hook (. (require "my.directory") :add-hook)]
    (hook :my.project on-directory-changed)))


{: project-root
 : setup}
  
;;; project.fnl ends here
