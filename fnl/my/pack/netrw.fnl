(module my.pack.netrw
  {require {b my.bufreg
            p my.project}})


(def- autocmd-init
  "augroup my_netrw
  autocmd!
  autocmd FileType netrw lua _T('my.pack.netrw', 'initialize')
  autocmd")


(def- autocmd-enable
  "augroup my_netrw_local
  autocmd! * <buffer>
  autocmd BufEnter <buffer> lua _T('my.pack.netrw', 'keep-initialized')
  autocmd")


(def- autocmd-disable
  "augroup my_netrw_local
  autocmd! * <buffer>
  autocmd")


(defn- enable []
  (vim.api.nvim_exec autocmd-enable false))


(defn- disable []
  (vim.api.nvim_exec autocmd-disable false))


(defn- configure [bufnr]
  (let [netrw-dir (vim.api.nvim_buf_get_var bufnr :netrw_curdir)
        dd (b.get-local bufnr :directory)]
    (when (~= dd netrw-dir)
      (b.set-local bufnr :directory netrw-dir)
      (p.defer-project-search bufnr netrw-dir))))


(defn keep-initialized []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
        ft (vim.api.nvim_buf_get_option bufnr :filetype)]
    (if (= ft "netrw")
      (configure bufnr)
      (disable))))


(defn initialize []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (configure bufnr)
    (enable)))
  

(defn setup []
  (vim.api.nvim_exec autocmd-init false)
  (set vim.g.netrw_keepdir 0))
