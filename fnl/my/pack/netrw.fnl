(local b (require :my.bufreg))
(local p (require :my.project))


(local autocmd-init
  "augroup my_netrw
  autocmd!
  autocmd FileType netrw lua _T('my.pack.netrw', 'initialize')
  augroup END")


(local autocmd-enable
  "augroup my_netrw_local
  autocmd! * <buffer>
  autocmd BufEnter <buffer> lua _T('my.pack.netrw', 'keep-initialized')
  augroup END")


(local autocmd-disable
  "augroup my_netrw_local
  autocmd! * <buffer>
  augroup END")


(fn enable []
  (vim.api.nvim_exec autocmd-enable false))


(fn disable []
  (vim.api.nvim_exec autocmd-disable false))


(fn configure [bufnr]
  (let [netrw-dir (vim.api.nvim_buf_get_var bufnr :netrw_curdir)
        dd (b.get-local bufnr :directory)]
    (when (~= dd netrw-dir)
      (b.set-local bufnr :directory netrw-dir)
      (p.defer-project-search bufnr netrw-dir))))


(fn keep-initialized []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
        ft (vim.api.nvim_buf_get_option bufnr :filetype)]
    (if (= ft "netrw")
      (configure bufnr)
      (disable))))


(fn initialize []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (configure bufnr)
    (enable)))
  

(fn setup []
  (vim.api.nvim_exec autocmd-init false)
  (set vim.g.netrw_keepdir 0))


{: setup
 : initialize
 : keep-initialized}
